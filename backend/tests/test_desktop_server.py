import socket

import pytest

from desktop_server import bind_backend_listener


def test_backend_listener_keeps_selected_fallback_port_owned():
    occupied = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    occupied.bind(("127.0.0.1", 0))
    occupied.listen(1)
    occupied_port = occupied.getsockname()[1]

    listener = bind_backend_listener("127.0.0.1", occupied_port)
    try:
        fallback_port = listener.getsockname()[1]
        assert fallback_port != occupied_port

        competitor = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            with pytest.raises(OSError):
                competitor.bind(("127.0.0.1", fallback_port))
        finally:
            competitor.close()
    finally:
        listener.close()
        occupied.close()
