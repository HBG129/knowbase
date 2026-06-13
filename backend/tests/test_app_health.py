from app.main import app


def test_api_routes_are_registered():
    paths = {route.path for route in app.routes}

    assert "/api/health" in paths
    assert "/api/auth/login" in paths
    assert "/api/kb/{kb_id}/documents" in paths
    assert "/api/kb/{kb_id}/chat" in paths
