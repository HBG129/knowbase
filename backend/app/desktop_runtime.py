"""Desktop runtime environment defaults."""
import json
import os
import secrets
from pathlib import Path

from app.config import include_desktop_cors_origins


def get_desktop_data_dir() -> Path:
    override = os.environ.get("KNOWBASE_DATA_DIR")
    if override:
        return Path(override)

    appdata = os.environ.get("APPDATA")
    if appdata:
        return Path(appdata) / "KnowBase"

    return Path.home() / ".knowbase"


def _load_or_create_secret(data_dir: Path) -> str:
    secret_path = data_dir / "app.secret"
    if secret_path.exists():
        secret = secret_path.read_text(encoding="utf-8").strip()
        if secret:
            return secret

    secret = secrets.token_urlsafe(48)
    secret_path.write_text(secret, encoding="utf-8")
    return secret


def configure_desktop_environment() -> Path:
    data_dir = get_desktop_data_dir()
    upload_dir = data_dir / "uploads"
    data_dir.mkdir(parents=True, exist_ok=True)
    upload_dir.mkdir(parents=True, exist_ok=True)
    secret = _load_or_create_secret(data_dir)

    db_path = (data_dir / "knowbase.db").resolve().as_posix()
    os.environ.setdefault("DATABASE_URL", f"sqlite+aiosqlite:///{db_path}")
    os.environ.setdefault("UPLOAD_DIR", str(upload_dir))
    os.environ.setdefault("JWT_SECRET_KEY", secret)
    os.environ.setdefault("API_KEY_ENCRYPTION_SECRET", os.environ["JWT_SECRET_KEY"])
    os.environ.setdefault("API_KEY_STORAGE_BACKEND", "windows-credential")
    os.environ.setdefault(
        "CORS_ORIGINS",
        json.dumps(include_desktop_cors_origins(["http://localhost:3000"])),
    )

    return data_dir
