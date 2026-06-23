from pathlib import Path

from app.desktop_runtime import configure_desktop_environment


def test_configure_desktop_environment_uses_override(monkeypatch, tmp_path):
    data_dir = tmp_path / "KnowBaseData"
    monkeypatch.setenv("KNOWBASE_DATA_DIR", str(data_dir))
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.delenv("UPLOAD_DIR", raising=False)
    monkeypatch.delenv("JWT_SECRET_KEY", raising=False)
    monkeypatch.delenv("API_KEY_ENCRYPTION_SECRET", raising=False)
    monkeypatch.delenv("API_KEY_STORAGE_BACKEND", raising=False)
    monkeypatch.delenv("CORS_ORIGINS", raising=False)

    configure_desktop_environment()

    assert data_dir.exists()
    assert (data_dir / "uploads").exists()
    assert "sqlite+aiosqlite:///" in __import__("os").environ["DATABASE_URL"]
    assert Path(__import__("os").environ["UPLOAD_DIR"]) == data_dir / "uploads"
    assert (data_dir / "app.secret").exists()
    assert __import__("os").environ["JWT_SECRET_KEY"]
    assert __import__("os").environ["API_KEY_ENCRYPTION_SECRET"] == __import__("os").environ["JWT_SECRET_KEY"]
    assert __import__("os").environ["API_KEY_STORAGE_BACKEND"] == "windows-credential"
    assert "tauri://localhost" in __import__("os").environ["CORS_ORIGINS"]


def test_configure_desktop_environment_does_not_override_existing_values(monkeypatch, tmp_path):
    data_dir = tmp_path / "KnowBaseData"
    monkeypatch.setenv("KNOWBASE_DATA_DIR", str(data_dir))
    monkeypatch.setenv("DATABASE_URL", "sqlite+aiosqlite:///custom.db")
    monkeypatch.setenv("UPLOAD_DIR", str(tmp_path / "custom-uploads"))
    monkeypatch.setenv("JWT_SECRET_KEY", "existing-jwt-secret")
    monkeypatch.setenv("API_KEY_ENCRYPTION_SECRET", "existing-api-secret")
    monkeypatch.setenv("API_KEY_STORAGE_BACKEND", "database")
    monkeypatch.setenv("CORS_ORIGINS", '["http://custom.example"]')

    configure_desktop_environment()

    assert __import__("os").environ["DATABASE_URL"] == "sqlite+aiosqlite:///custom.db"
    assert Path(__import__("os").environ["UPLOAD_DIR"]) == tmp_path / "custom-uploads"
    assert __import__("os").environ["JWT_SECRET_KEY"] == "existing-jwt-secret"
    assert __import__("os").environ["API_KEY_ENCRYPTION_SECRET"] == "existing-api-secret"
    assert __import__("os").environ["API_KEY_STORAGE_BACKEND"] == "database"
    assert __import__("os").environ["CORS_ORIGINS"] == '["http://custom.example"]'


def test_configure_desktop_environment_reuses_generated_secret(monkeypatch, tmp_path):
    data_dir = tmp_path / "KnowBaseData"
    monkeypatch.setenv("KNOWBASE_DATA_DIR", str(data_dir))
    monkeypatch.delenv("JWT_SECRET_KEY", raising=False)
    monkeypatch.delenv("API_KEY_ENCRYPTION_SECRET", raising=False)
    monkeypatch.delenv("API_KEY_STORAGE_BACKEND", raising=False)

    configure_desktop_environment()
    first_secret = __import__("os").environ["JWT_SECRET_KEY"]

    monkeypatch.delenv("JWT_SECRET_KEY", raising=False)
    monkeypatch.delenv("API_KEY_ENCRYPTION_SECRET", raising=False)
    configure_desktop_environment()

    assert __import__("os").environ["JWT_SECRET_KEY"] == first_secret
    assert (data_dir / "app.secret").read_text(encoding="utf-8") == first_secret
