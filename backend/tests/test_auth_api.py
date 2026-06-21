from sqlalchemy import select

from app.models.user import User


def register_user(client, email="owner@example.com", username="owner"):
    response = client.post(
        "/api/auth/register",
        json={"email": email, "username": username, "password": "password123"},
    )
    assert response.status_code == 201, response.text
    return response.json()


def login_user(client, email="owner@example.com"):
    response = client.post(
        "/api/auth/login",
        json={"email": email, "password": "password123"},
    )
    assert response.status_code == 200, response.text
    return response.json()


def auth_headers(token_response):
    return {"Authorization": "Bearer " + token_response["access_token"]}


def test_register_login_and_fetch_current_user(client):
    user = register_user(client)
    tokens = login_user(client)

    response = client.get("/api/auth/me", headers=auth_headers(tokens))

    assert response.status_code == 200, response.text
    assert response.json()["id"] == user["id"]
    assert response.json()["email"] == "owner@example.com"
    assert response.json()["has_api_key"] is False


def test_register_rejects_invalid_email(client):
    response = client.post(
        "/api/auth/register",
        json={"email": "not-an-email", "username": "owner", "password": "password123"},
    )

    assert response.status_code == 422


def test_login_rejects_invalid_email(client):
    response = client.post(
        "/api/auth/login",
        json={"email": "not-an-email", "password": "password123"},
    )

    assert response.status_code == 422


def test_register_rejects_short_password(client):
    response = client.post(
        "/api/auth/register",
        json={"email": "owner@example.com", "username": "owner", "password": "short"},
    )

    assert response.status_code == 422


def test_register_rejects_duplicate_email(client):
    register_user(client)

    response = client.post(
        "/api/auth/register",
        json={"email": "owner@example.com", "username": "another", "password": "password123"},
    )

    assert response.status_code == 400


def test_refresh_rotates_refresh_token(client):
    register_user(client)
    tokens = login_user(client)

    response = client.post(
        "/api/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )

    assert response.status_code == 200, response.text
    assert response.json()["access_token"]
    assert response.json()["refresh_token"] != tokens["refresh_token"]


def test_refresh_token_cannot_be_reused(client):
    register_user(client)
    tokens = login_user(client)
    first_refresh = client.post(
        "/api/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert first_refresh.status_code == 200, first_refresh.text

    reused = client.post(
        "/api/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )

    assert reused.status_code == 401


def test_api_key_provider_must_be_supported(client):
    register_user(client)
    headers = auth_headers(login_user(client))

    response = client.put(
        "/api/auth/me/api-key",
        json={"api_key": "secret", "api_provider": "unknown"},
        headers=headers,
    )

    assert response.status_code == 400


def test_api_key_can_be_set_and_cleared_without_echoing_secret(client):
    register_user(client)
    headers = auth_headers(login_user(client))

    set_response = client.put(
        "/api/auth/me/api-key",
        json={"api_key": "secret", "api_provider": "openai"},
        headers=headers,
    )

    assert set_response.status_code == 200, set_response.text
    assert set_response.json()["api_provider"] == "openai"
    assert set_response.json()["has_api_key"] is True
    assert "secret" not in set_response.text

    clear_response = client.delete("/api/auth/me/api-key", headers=headers)

    assert clear_response.status_code == 200, clear_response.text
    assert clear_response.json()["api_provider"] is None
    assert clear_response.json()["has_api_key"] is False


def test_api_key_is_not_stored_as_plaintext(client):
    register_user(client)
    headers = auth_headers(login_user(client))

    response = client.put(
        "/api/auth/me/api-key",
        json={"api_key": "sk-customer-secret", "api_provider": "openai"},
        headers=headers,
    )

    assert response.status_code == 200, response.text

    SessionLocal = client.app.state.testing_session_factory
    with SessionLocal() as db:
        user = db.execute(select(User).where(User.email == "owner@example.com")).scalar_one()

    assert user.api_key != "sk-customer-secret"
    assert user.api_key
