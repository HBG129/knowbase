import json

from tests.test_auth_api import auth_headers, login_user, register_user


def _create_kb_with_text_document(client, headers, tmp_path, monkeypatch):
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(tmp_path / "uploads"))
    kb = client.post(
        "/api/kb",
        json={"name": "Policy Docs"},
        headers=headers,
    ).json()
    upload = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={"file": ("refund.txt", b"Refund policy: contact support within 30 days.", "text/plain")},
        headers=headers,
    )
    assert upload.status_code == 201, upload.text
    return kb


def _sse_events(response_text):
    events = []
    for block in response_text.strip().split("\n\n"):
        if not block.startswith("data: "):
            continue
        events.append(json.loads(block[len("data: "):]))
    return events


def _stub_llm(monkeypatch, answer="Contact support within 30 days."):
    def fake_llm_stream(user, system_prompt, messages):
        yield answer

    monkeypatch.setattr("app.api.chat.llm_stream", fake_llm_stream)


def test_chat_stream_returns_citations_and_persists_messages(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    kb = _create_kb_with_text_document(client, headers, tmp_path, monkeypatch)

    def fake_llm_stream(user, system_prompt, messages):
        assert "Refund policy" in system_prompt
        assert messages[-1]["content"] == "What is the refund policy?"
        yield "Contact support within 30 days."

    monkeypatch.setattr("app.api.chat.llm_stream", fake_llm_stream)

    response = client.post(
        "/api/kb/" + kb["id"] + "/chat",
        json={"message": "What is the refund policy?"},
        headers=headers,
    )

    assert response.status_code == 200, response.text
    events = _sse_events(response.text)
    assert events[0] == {"type": "chunk", "content": "Contact support within 30 days."}
    assert events[-1]["type"] == "done"
    assert events[-1]["conversation_id"]
    assert events[-1]["citations"]
    assert events[-1]["citations"][0]["doc_filename"] == "refund.txt"

    messages = client.get(
        "/api/kb/" + kb["id"] + "/conversations/" + events[-1]["conversation_id"] + "/messages",
        headers=headers,
    )
    assert messages.status_code == 200, messages.text
    stored = messages.json()
    assert [message["role"] for message in stored] == ["user", "assistant"]
    assert stored[0]["content"] == "What is the refund policy?"
    assert stored[1]["content"] == "Contact support within 30 days."
    assert json.loads(stored[1]["citations_json"])[0]["doc_filename"] == "refund.txt"


def test_chat_rejects_empty_message(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    kb = _create_kb_with_text_document(client, headers, tmp_path, monkeypatch)

    response = client.post(
        "/api/kb/" + kb["id"] + "/chat",
        json={"message": "   "},
        headers=headers,
    )

    assert response.status_code == 400


def test_non_member_cannot_chat(client, monkeypatch, tmp_path):
    register_user(client, email="owner@example.com", username="owner")
    owner_headers = auth_headers(login_user(client, email="owner@example.com"))
    kb = _create_kb_with_text_document(client, owner_headers, tmp_path, monkeypatch)
    register_user(client, email="outsider@example.com", username="outsider")
    outsider_headers = auth_headers(login_user(client, email="outsider@example.com"))

    response = client.post(
        "/api/kb/" + kb["id"] + "/chat",
        json={"message": "What is the refund policy?"},
        headers=outsider_headers,
    )

    assert response.status_code == 403


def test_chat_rejects_conversation_from_another_knowledge_base(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    kb_one = _create_kb_with_text_document(client, headers, tmp_path / "one", monkeypatch)
    kb_two = _create_kb_with_text_document(client, headers, tmp_path / "two", monkeypatch)
    _stub_llm(monkeypatch)
    first_chat = client.post(
        "/api/kb/" + kb_one["id"] + "/chat",
        json={"message": "What is the refund policy?"},
        headers=headers,
    )
    conv_id = _sse_events(first_chat.text)[-1]["conversation_id"]

    response = client.post(
        "/api/kb/" + kb_two["id"] + "/chat",
        json={"message": "Use the old conversation", "conversation_id": conv_id},
        headers=headers,
    )

    assert response.status_code == 404


def test_messages_endpoint_rejects_conversation_from_another_knowledge_base(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    kb_one = _create_kb_with_text_document(client, headers, tmp_path / "one", monkeypatch)
    kb_two = _create_kb_with_text_document(client, headers, tmp_path / "two", monkeypatch)
    _stub_llm(monkeypatch)
    first_chat = client.post(
        "/api/kb/" + kb_one["id"] + "/chat",
        json={"message": "What is the refund policy?"},
        headers=headers,
    )
    conv_id = _sse_events(first_chat.text)[-1]["conversation_id"]

    response = client.get(
        "/api/kb/" + kb_two["id"] + "/conversations/" + conv_id + "/messages",
        headers=headers,
    )

    assert response.status_code == 404


def test_delete_conversation_rejects_conversation_from_another_knowledge_base(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    kb_one = _create_kb_with_text_document(client, headers, tmp_path / "one", monkeypatch)
    kb_two = _create_kb_with_text_document(client, headers, tmp_path / "two", monkeypatch)
    _stub_llm(monkeypatch)
    first_chat = client.post(
        "/api/kb/" + kb_one["id"] + "/chat",
        json={"message": "What is the refund policy?"},
        headers=headers,
    )
    conv_id = _sse_events(first_chat.text)[-1]["conversation_id"]

    response = client.delete(
        "/api/kb/" + kb_two["id"] + "/conversations/" + conv_id,
        headers=headers,
    )

    assert response.status_code == 404
    messages = client.get(
        "/api/kb/" + kb_one["id"] + "/conversations/" + conv_id + "/messages",
        headers=headers,
    )
    assert messages.status_code == 200


def test_clear_messages_rejects_conversation_from_another_knowledge_base(client, monkeypatch, tmp_path):
    register_user(client)
    headers = auth_headers(login_user(client))
    kb_one = _create_kb_with_text_document(client, headers, tmp_path / "one", monkeypatch)
    kb_two = _create_kb_with_text_document(client, headers, tmp_path / "two", monkeypatch)
    _stub_llm(monkeypatch)
    first_chat = client.post(
        "/api/kb/" + kb_one["id"] + "/chat",
        json={"message": "What is the refund policy?"},
        headers=headers,
    )
    conv_id = _sse_events(first_chat.text)[-1]["conversation_id"]

    response = client.delete(
        "/api/kb/" + kb_two["id"] + "/conversations/" + conv_id + "/messages",
        headers=headers,
    )

    assert response.status_code == 404
    messages = client.get(
        "/api/kb/" + kb_one["id"] + "/conversations/" + conv_id + "/messages",
        headers=headers,
    )
    assert len(messages.json()) == 2
