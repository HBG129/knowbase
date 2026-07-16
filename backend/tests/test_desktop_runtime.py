import os
from pathlib import Path
import subprocess
import sys

from app.desktop_runtime import configure_desktop_environment


def test_desktop_environment_is_configured_before_settings_load(tmp_path):
    data_dir = tmp_path / "FreshDesktopData"
    env = os.environ.copy()
    env["KNOWBASE_DATA_DIR"] = str(data_dir)
    for key in ("DATABASE_URL", "UPLOAD_DIR", "JWT_SECRET_KEY", "API_KEY_ENCRYPTION_SECRET"):
        env.pop(key, None)

    code = """
from app.desktop_runtime import configure_desktop_environment
configure_desktop_environment()
from app.config import settings
import os
assert settings.DATABASE_URL == os.environ["DATABASE_URL"]
assert settings.UPLOAD_DIR == os.environ["UPLOAD_DIR"]
"""
    result = subprocess.run(
        [sys.executable, "-c", code],
        cwd=Path(__file__).resolve().parents[1],
        env=env,
        capture_output=True,
        text=True,
        timeout=15,
        check=False,
    )

    assert result.returncode == 0, result.stdout + result.stderr


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
