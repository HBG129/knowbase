import tomllib
from pathlib import Path

from passlib.context import CryptContext

from app.config import Settings, settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)


def test_default_hs256_secret_meets_minimum_key_length():
    default_secret = Settings.model_fields["JWT_SECRET_KEY"].default

    assert len(default_secret.encode("utf-8")) >= 32


def test_jwt_dependency_does_not_install_vulnerable_ecdsa_package():
    pyproject_path = Path(__file__).parents[1] / "pyproject.toml"
    dependencies = tomllib.loads(pyproject_path.read_text(encoding="utf-8"))["project"]["dependencies"]
    normalized = [dependency.lower() for dependency in dependencies]

    assert any(dependency.startswith("pyjwt") for dependency in normalized)
    assert not any(dependency.startswith("python-jose") for dependency in normalized)


def test_access_token_round_trip(monkeypatch):
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "test-jwt-secret-with-at-least-32-bytes")
    token = create_access_token("user-123")

    payload = decode_token(token)

    assert payload is not None
    assert payload["sub"] == "user-123"
    assert payload["type"] == "access"


def test_refresh_token_round_trip_has_unique_identifier(monkeypatch):
    monkeypatch.setattr(settings, "JWT_SECRET_KEY", "test-jwt-secret-with-at-least-32-bytes")
    token = create_refresh_token("user-123")

    payload = decode_token(token)

    assert payload is not None
    assert payload["sub"] == "user-123"
    assert payload["type"] == "refresh"
    assert payload["jti"]


def test_invalid_token_returns_none():
    assert decode_token("not-a-jwt") is None


def test_long_passwords_are_not_silently_truncated():
    password = "a" * 72 + "-first"
    different_suffix = "a" * 72 + "-second"

    hashed = hash_password(password)

    assert verify_password(password, hashed)
    assert not verify_password(different_suffix, hashed)


def test_legacy_bcrypt_passwords_remain_valid():
    legacy_context = CryptContext(schemes=["bcrypt"])
    legacy_hash = legacy_context.hash("legacy-password")

    assert verify_password("legacy-password", legacy_hash)
