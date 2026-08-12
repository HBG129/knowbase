"""Packaged desktop backend entrypoint."""
import multiprocessing
import os
import socket
from pathlib import Path

import uvicorn

from app.desktop_runtime import configure_desktop_environment


def bind_backend_listener(host: str, preferred_port: int) -> socket.socket:
    ports = (preferred_port, 0) if preferred_port else (0,)
    for port in ports:
        listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        if hasattr(socket, "SO_EXCLUSIVEADDRUSE"):
            listener.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        try:
            listener.bind((host, port))
            listener.listen(2048)
            return listener
        except OSError:
            listener.close()
            if port == 0:
                raise
    raise RuntimeError("Backend listener could not be created")


def main() -> None:
    multiprocessing.freeze_support()
    configure_desktop_environment()
    from app.main import app

    host = os.environ.get("KNOWBASE_BACKEND_HOST", "127.0.0.1")
    port = int(os.environ.get("KNOWBASE_BACKEND_PORT", "8000"))
    listener = bind_backend_listener(host, port)
    ready_file = os.environ.get("KNOWBASE_BACKEND_READY_FILE")
    if ready_file:
        Path(ready_file).write_text(str(listener.getsockname()[1]), encoding="ascii")
    config = uvicorn.Config(app, log_level="info")
    server = uvicorn.Server(config)
    server.run(sockets=[listener])


if __name__ == "__main__":
    main()
