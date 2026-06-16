from pathlib import Path

from app.desktop_runtime import configure_desktop_environment


def test_configure_desktop_environment_uses_override(monkeypatch, tmp_path):
    data_dir = tmp_path / "KnowBaseData"
    monkeypatch.setenv("KNOWBASE_DATA_DIR", str(data_dir))
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.delenv("UPLOAD_DIR", raising=False)

    configure_desktop_environment()

    assert data_dir.exists()
    assert (data_dir / "uploads").exists()
    assert "sqlite+aiosqlite:///" in __import__("os").environ["DATABASE_URL"]
    assert Path(__import__("os").environ["UPLOAD_DIR"]) == data_dir / "uploads"


def test_configure_desktop_environment_does_not_override_existing_values(monkeypatch, tmp_path):
    data_dir = tmp_path / "KnowBaseData"
    monkeypatch.setenv("KNOWBASE_DATA_DIR", str(data_dir))
    monkeypatch.setenv("DATABASE_URL", "sqlite+aiosqlite:///custom.db")
    monkeypatch.setenv("UPLOAD_DIR", str(tmp_path / "custom-uploads"))

    configure_desktop_environment()

    assert __import__("os").environ["DATABASE_URL"] == "sqlite+aiosqlite:///custom.db"
    assert Path(__import__("os").environ["UPLOAD_DIR"]) == tmp_path / "custom-uploads"
