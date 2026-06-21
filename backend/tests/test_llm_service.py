from app.core.security import encrypt_api_key
from app.models.user import User
from app.services.llm_service import _resolve_llm


def test_resolve_llm_decrypts_stored_user_api_key():
    user = User(api_key=encrypt_api_key("sk-customer-secret"), api_provider="openai")

    config = _resolve_llm(user)

    assert config["api_key"] == "sk-customer-secret"


def test_resolve_llm_accepts_legacy_plaintext_user_api_key():
    user = User(api_key="legacy-secret", api_provider="openai")

    config = _resolve_llm(user)

    assert config["api_key"] == "legacy-secret"


def test_resolve_llm_reads_credential_reference(monkeypatch):
    from app.services import secret_store

    monkeypatch.setattr(secret_store, "read_secret", lambda target: "sk-customer-secret")
    user = User(api_key="cred:v1:KnowBase:test-user:llm-api-key", api_provider="openai")

    config = _resolve_llm(user)

    assert config["api_key"] == "sk-customer-secret"
