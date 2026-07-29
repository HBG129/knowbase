from tests.test_auth_api import auth_headers, login_user, register_user


def _create_kb_with_csv(client, headers, tmp_path, monkeypatch):
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(tmp_path / "uploads"))
    kb = client.post("/api/kb", json={"name": "Sales Data"}, headers=headers).json()
    upload = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={
            "file": (
                "sales.csv",
                b"month,channel,revenue\nJan,web,1200\nFeb,store,950\nMar,web,1300\n",
                "text/csv",
            )
        },
        headers=headers,
    )
    assert upload.status_code == 201, upload.text
    return kb, upload.json()


def _configure_api_key(client, headers):
    response = client.put(
        "/api/auth/me/api-key",
        json={"api_key": "sk-analysis-test", "api_provider": "openai"},
        headers=headers,
    )
    assert response.status_code == 200, response.text


def test_analysis_datasets_lists_completed_csv_documents(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    kb, doc = _create_kb_with_csv(client, headers, tmp_path, monkeypatch)

    response = client.get("/api/kb/" + kb["id"] + "/analysis/datasets", headers=headers)

    assert response.status_code == 200, response.text
    datasets = response.json()
    assert datasets[0]["doc_id"] == doc["id"]
    assert datasets[0]["filename"] == "sales.csv"
    assert datasets[0]["row_count"] == 3
    assert datasets[0]["column_count"] == 3
    assert datasets[0]["recommended_questions"]


def test_analysis_preview_returns_rows_and_profile(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    kb, doc = _create_kb_with_csv(client, headers, tmp_path, monkeypatch)

    response = client.get(
        "/api/kb/" + kb["id"] + "/analysis/datasets/" + doc["id"] + "/preview",
        headers=headers,
    )

    assert response.status_code == 200, response.text
    preview = response.json()
    assert preview["columns"] == ["month", "channel", "revenue"]
    assert preview["rows"][0] == ["Jan", "web", "1200"]
    assert preview["profile"]["row_count"] == 3


def test_analysis_query_executes_llm_sql_and_saves_run(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    _configure_api_key(client, headers)
    kb, doc = _create_kb_with_csv(client, headers, tmp_path, monkeypatch)

    def fake_chat_sync(user, system_prompt, messages, temperature=0.2):
        content = messages[-1]["content"]
        if "Return strict JSON" in content:
            return '{"sql":"select channel, sum(revenue) as total_revenue from dataset group by channel order by total_revenue desc","chart_type":"bar","summary_goal":"Summarize revenue by channel"}'
        return "Web has the highest revenue."

    monkeypatch.setattr("app.services.analysis_service.chat_sync", fake_chat_sync)

    response = client.post(
        "/api/kb/" + kb["id"] + "/analysis/query",
        json={"doc_id": doc["id"], "question": "Which channel has the most revenue?"},
        headers=headers,
    )

    assert response.status_code == 200, response.text
    result = response.json()
    assert result["run_id"]
    assert result["columns"] == ["channel", "total_revenue"]
    assert result["rows"] == [["web", 2500], ["store", 950]]
    assert result["chart"]["type"] == "bar"
    assert result["summary"] == "Web has the highest revenue."

    runs = client.get("/api/kb/" + kb["id"] + "/analysis/runs", headers=headers)
    assert runs.status_code == 200, runs.text
    assert runs.json()[0]["id"] == result["run_id"]


def test_analysis_query_rejects_dangerous_llm_sql(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    _configure_api_key(client, headers)
    kb, doc = _create_kb_with_csv(client, headers, tmp_path, monkeypatch)

    def fake_chat_sync(user, system_prompt, messages, temperature=0.2):
        return '{"sql":"drop table dataset","chart_type":"table","summary_goal":"Destroy data"}'

    monkeypatch.setattr("app.services.analysis_service.chat_sync", fake_chat_sync)

    response = client.post(
        "/api/kb/" + kb["id"] + "/analysis/query",
        json={"doc_id": doc["id"], "question": "Delete this data"},
        headers=headers,
    )

    assert response.status_code == 400
    runs = client.get("/api/kb/" + kb["id"] + "/analysis/runs", headers=headers)
    assert runs.status_code == 200, runs.text
    assert runs.json()[0]["question"] == "Delete this data"
    assert runs.json()[0]["error_message"]
    assert runs.json()[0]["chart"] == {
        "type": "table",
        "x": "",
        "y": "",
        "series": [],
        "title": "Delete this data",
    }


def test_analysis_query_saves_run_when_safe_sql_fails_execution(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    _configure_api_key(client, headers)
    kb, doc = _create_kb_with_csv(client, headers, tmp_path, monkeypatch)

    def fake_chat_sync(user, system_prompt, messages, temperature=0.2):
        return '{"sql":"select missing_column from dataset","chart_type":"table","summary_goal":"Explain missing column"}'

    monkeypatch.setattr("app.services.analysis_service.chat_sync", fake_chat_sync)

    response = client.post(
        "/api/kb/" + kb["id"] + "/analysis/query",
        json={"doc_id": doc["id"], "question": "Analyze missing column"},
        headers=headers,
    )

    assert response.status_code == 400
    assert "could not be executed" in response.json()["detail"]
    runs = client.get("/api/kb/" + kb["id"] + "/analysis/runs", headers=headers)
    assert runs.status_code == 200, runs.text
    assert len(runs.json()) == 1
    assert runs.json()[0]["sql"] == "select missing_column from dataset"
    assert "missing_column" in runs.json()[0]["error_message"]


def test_analysis_query_returns_rows_when_summary_generation_fails(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    _configure_api_key(client, headers)
    kb, doc = _create_kb_with_csv(client, headers, tmp_path, monkeypatch)

    def fake_chat_sync(user, system_prompt, messages, temperature=0.2):
        content = messages[-1]["content"]
        if "Return strict JSON" in content:
            return '{"sql":"select channel, sum(revenue) as total_revenue from dataset group by channel order by total_revenue desc","chart_type":"bar","summary_goal":"Summarize revenue"}'
        raise ValueError("summary provider unavailable")

    monkeypatch.setattr("app.services.analysis_service.chat_sync", fake_chat_sync)

    response = client.post(
        "/api/kb/" + kb["id"] + "/analysis/query",
        json={"doc_id": doc["id"], "question": "Summarize revenue by channel"},
        headers=headers,
    )

    assert response.status_code == 200, response.text
    result = response.json()
    assert result["columns"] == ["channel", "total_revenue"]
    assert result["rows"] == [["web", 2500], ["store", 950]]
    assert "Summary unavailable" in result["summary"]

    runs = client.get("/api/kb/" + kb["id"] + "/analysis/runs", headers=headers)
    assert runs.status_code == 200, runs.text
    assert runs.json()[0]["summary"] == result["summary"]


def test_analysis_summary_prompt_explicitly_requires_chinese_for_chinese_question(
    client,
    monkeypatch,
    tmp_path,
):
    register_user(client)
    headers = auth_headers(login_user(client))
    _configure_api_key(client, headers)
    kb, doc = _create_kb_with_csv(client, headers, tmp_path, monkeypatch)
    prompts = []

    def fake_chat_sync(user, system_prompt, messages, temperature=0.2):
        prompts.append(messages[0]["content"])
        if len(prompts) == 1:
            return '{"sql":"select channel, sum(revenue) as total_revenue from dataset group by channel","chart_type":"bar","summary_goal":"Summarize revenue"}'
        return "网页渠道收入最高。"

    monkeypatch.setattr("app.services.analysis_service.chat_sync", fake_chat_sync)

    response = client.post(
        "/api/kb/" + kb["id"] + "/analysis/query",
        json={"doc_id": doc["id"], "question": "按渠道汇总收入。"},
        headers=headers,
    )

    assert response.status_code == 200, response.text
    assert "The user's question is in Chinese. Respond only in Chinese." in prompts[1]


def test_non_member_cannot_access_analysis(client, monkeypatch, tmp_path):
    register_user(client, email="owner@example.com", username="owner")
    owner_headers = auth_headers(login_user(client, email="owner@example.com"))
    kb, _doc = _create_kb_with_csv(client, owner_headers, tmp_path, monkeypatch)
    register_user(client, email="outsider@example.com", username="outsider")
    outsider_headers = auth_headers(login_user(client, email="outsider@example.com"))

    response = client.get("/api/kb/" + kb["id"] + "/analysis/datasets", headers=outsider_headers)

    assert response.status_code == 403


def test_deleting_csv_document_removes_analysis_runs(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    _configure_api_key(client, headers)
    kb, doc = _create_kb_with_csv(client, headers, tmp_path, monkeypatch)

    def fake_chat_sync(user, system_prompt, messages, temperature=0.2):
        content = messages[-1]["content"]
        if "Return strict JSON" in content:
            return '{"sql":"select channel, sum(revenue) as total_revenue from dataset group by channel","chart_type":"bar","summary_goal":"Summarize revenue"}'
        return "Revenue summarized."

    monkeypatch.setattr("app.services.analysis_service.chat_sync", fake_chat_sync)
    analysis = client.post(
        "/api/kb/" + kb["id"] + "/analysis/query",
        json={"doc_id": doc["id"], "question": "Summarize revenue"},
        headers=headers,
    )
    assert analysis.status_code == 200, analysis.text

    deleted = client.delete("/api/kb/" + kb["id"] + "/documents/" + doc["id"], headers=headers)
    assert deleted.status_code == 204, deleted.text

    runs = client.get("/api/kb/" + kb["id"] + "/analysis/runs", headers=headers)
    assert runs.status_code == 200, runs.text
    assert runs.json() == []


def test_analysis_query_requires_user_api_key_even_with_system_fallback(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    kb, doc = _create_kb_with_csv(client, headers, tmp_path, monkeypatch)
    monkeypatch.setattr("app.config.settings.OPENAI_API_KEY", "system-fallback-key")

    def unexpected_chat_sync(*args, **kwargs):
        raise AssertionError("LLM must not be called without a user API key")

    monkeypatch.setattr("app.services.analysis_service.chat_sync", unexpected_chat_sync)

    response = client.post(
        "/api/kb/" + kb["id"] + "/analysis/query",
        json={"doc_id": doc["id"], "question": "Summarize revenue"},
        headers=headers,
    )

    assert response.status_code == 400
    assert "API key" in response.json()["detail"]


def test_analysis_routes_publish_response_schemas(client):
    paths = client.get("/openapi.json").json()["paths"]

    query_schema = paths["/api/kb/{kb_id}/analysis/query"]["post"]["responses"]["200"]["content"][
        "application/json"
    ]["schema"]
    dataset_schema = paths["/api/kb/{kb_id}/analysis/datasets"]["get"]["responses"]["200"]["content"][
        "application/json"
    ]["schema"]

    assert query_schema["$ref"].endswith("/AnalysisRunResponse")
    assert dataset_schema["items"]["$ref"].endswith("/AnalysisDatasetResponse")
