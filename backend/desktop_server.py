"""Packaged desktop backend entrypoint."""
import os

import uvicorn

from app.desktop_runtime import configure_desktop_environment


def main() -> None:
    configure_desktop_environment()
    from app.main import app

    host = os.environ.get("KNOWBASE_BACKEND_HOST", "127.0.0.1")
    port = int(os.environ.get("KNOWBASE_BACKEND_PORT", "8000"))
    uvicorn.run(app, host=host, port=port, log_level="info")


if __name__ == "__main__":
    main()
