"""Desktop runtime environment defaults."""
import os
from pathlib import Path


def get_desktop_data_dir() -> Path:
    override = os.environ.get("KNOWBASE_DATA_DIR")
    if override:
        return Path(override)

    appdata = os.environ.get("APPDATA")
    if appdata:
        return Path(appdata) / "KnowBase"

    return Path.home() / ".knowbase"


def configure_desktop_environment() -> Path:
    data_dir = get_desktop_data_dir()
    upload_dir = data_dir / "uploads"
    data_dir.mkdir(parents=True, exist_ok=True)
    upload_dir.mkdir(parents=True, exist_ok=True)

    db_path = (data_dir / "knowbase.db").resolve().as_posix()
    os.environ.setdefault("DATABASE_URL", f"sqlite+aiosqlite:///{db_path}")
    os.environ.setdefault("UPLOAD_DIR", str(upload_dir))

    return data_dir
