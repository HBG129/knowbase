from app.main import app


def test_api_routes_are_registered():
    paths = {route.path for route in app.routes}

    assert "/api/health" in paths
    assert "/api/desktop/health" in paths
    assert "/api/auth/login" in paths
    assert "/api/kb/{kb_id}/documents" in paths
    assert "/api/kb/{kb_id}/chat" in paths


def test_desktop_webview_origins_are_allowed(client):
    for origin in ("tauri://localhost", "http://tauri.localhost", "https://tauri.localhost"):
        response = client.options(
            "/api/auth/register",
            headers={
                "Origin": origin,
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "content-type",
            },
        )

        assert response.status_code == 200
        assert response.headers["access-control-allow-origin"] == origin


def test_desktop_token_keeps_health_public_but_protects_api_routes(client, monkeypatch):
    monkeypatch.setenv("KNOWBASE_DESKTOP_TOKEN", "desktop-capability-token")

    assert client.get("/api/health").json() == {"status": "ok"}
    assert client.get(
        "/api/desktop/health",
        headers={"X-KnowBase-Desktop-Token": "wrong-token"},
    ).status_code == 403

    response = client.get(
        "/api/desktop/health",
        headers={"X-KnowBase-Desktop-Token": "desktop-capability-token"},
    )

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
