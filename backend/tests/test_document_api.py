from pathlib import Path

from sqlalchemy import select

from app.models.document import Document, DocumentChunk
from tests.test_auth_api import auth_headers, login_user, register_user


def test_upload_text_document_stores_chunks_and_lists_document(client, monkeypatch, tmp_path):
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(tmp_path / "uploads"))
    register_user(client)
    headers = auth_headers(login_user(client))
    kb = client.post(
        "/api/kb",
        json={"name": "Support Docs"},
        headers=headers,
    ).json()

    upload_response = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={"file": ("faq.txt", b"Refund policy: contact support within 30 days.", "text/plain")},
        headers=headers,
    )

    assert upload_response.status_code == 201, upload_response.text
    uploaded = upload_response.json()
    assert uploaded["filename"] == "faq.txt"
    assert uploaded["status"] == "completed"
    assert uploaded["chunk_count"] == 1

    list_response = client.get("/api/kb/" + kb["id"] + "/documents", headers=headers)
    assert list_response.status_code == 200, list_response.text
    assert list_response.json()[0]["id"] == uploaded["id"]

    with client.app.state.testing_session_factory() as db:
        chunks = db.execute(select(DocumentChunk)).scalars().all()
    assert len(chunks) == 1
    assert "Refund policy" in chunks[0].content


def test_delete_document_removes_stored_chunks(client, monkeypatch, tmp_path):
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(tmp_path / "uploads"))
    register_user(client)
    headers = auth_headers(login_user(client))
    kb = client.post(
        "/api/kb",
        json={"name": "Support Docs"},
        headers=headers,
    ).json()
    uploaded = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={"file": ("faq.txt", b"Refund policy: contact support within 30 days.", "text/plain")},
        headers=headers,
    ).json()

    delete_response = client.delete(
        "/api/kb/" + kb["id"] + "/documents/" + uploaded["id"],
        headers=headers,
    )

    assert delete_response.status_code == 204, delete_response.text
    with client.app.state.testing_session_factory() as db:
        chunks = db.execute(select(DocumentChunk)).scalars().all()
    assert chunks == []


def test_upload_rejects_empty_file_without_creating_document(client, monkeypatch, tmp_path):
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(tmp_path / "uploads"))
    register_user(client)
    headers = auth_headers(login_user(client))
    kb = client.post("/api/kb", json={"name": "Support Docs"}, headers=headers).json()

    response = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={"file": ("empty.txt", b"", "text/plain")},
        headers=headers,
    )

    assert response.status_code == 400
    with client.app.state.testing_session_factory() as db:
        assert db.execute(select(Document)).scalars().all() == []
    upload_dir = tmp_path / "uploads"
    assert not upload_dir.exists() or list(upload_dir.iterdir()) == []


def test_upload_rejects_oversized_file_without_creating_document(client, monkeypatch, tmp_path):
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(tmp_path / "uploads"))
    monkeypatch.setattr("app.config.settings.MAX_UPLOAD_SIZE_MB", 1)
    register_user(client)
    headers = auth_headers(login_user(client))
    kb = client.post("/api/kb", json={"name": "Support Docs"}, headers=headers).json()

    response = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={"file": ("large.txt", b"x" * (1024 * 1024 + 1), "text/plain")},
        headers=headers,
    )

    assert response.status_code == 400
    with client.app.state.testing_session_factory() as db:
        assert db.execute(select(Document)).scalars().all() == []
    upload_dir = tmp_path / "uploads"
    assert not upload_dir.exists() or list(upload_dir.iterdir()) == []


def test_upload_sanitizes_path_traversal_filename(client, monkeypatch, tmp_path):
    upload_dir = tmp_path / "uploads"
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(upload_dir))
    register_user(client)
    headers = auth_headers(login_user(client))
    kb = client.post("/api/kb", json={"name": "Support Docs"}, headers=headers).json()

    response = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={"file": ("../escape.txt", b"Safe content.", "text/plain")},
        headers=headers,
    )

    assert response.status_code == 201, response.text
    with client.app.state.testing_session_factory() as db:
        doc = db.execute(select(Document)).scalar_one()
    assert doc.filename == "escape.txt"
    assert Path(doc.file_path).resolve().parent == upload_dir.resolve()
    assert not (tmp_path / "escape.txt").exists()


def test_failed_ingestion_removes_file_and_document_record(client, monkeypatch, tmp_path):
    upload_dir = tmp_path / "uploads"
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(upload_dir))
    register_user(client)
    headers = auth_headers(login_user(client))
    kb = client.post("/api/kb", json={"name": "Support Docs"}, headers=headers).json()

    def fail_ingest(db, doc, user):
        raise ValueError("parse failed")

    monkeypatch.setattr("app.api.document.ingest_document", fail_ingest)

    response = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={"file": ("broken.txt", b"Broken content.", "text/plain")},
        headers=headers,
    )

    assert response.status_code == 400
    with client.app.state.testing_session_factory() as db:
        assert db.execute(select(Document)).scalars().all() == []
        assert db.execute(select(DocumentChunk)).scalars().all() == []
    assert not upload_dir.exists() or list(upload_dir.iterdir()) == []
