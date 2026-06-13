from sqlalchemy import select

from app.models.conversation import Conversation, Message
from app.models.document import Document, DocumentChunk
from app.models.knowledge_base import KnowledgeBaseMember
from tests.test_auth_api import auth_headers, login_user, register_user


def test_user_can_create_list_update_and_delete_own_knowledge_base(client):
    register_user(client)
    tokens = login_user(client)
    headers = auth_headers(tokens)

    create_response = client.post(
        "/api/kb",
        json={"name": "Product Docs", "description": "Internal docs"},
        headers=headers,
    )
    assert create_response.status_code == 201, create_response.text
    kb = create_response.json()
    assert kb["name"] == "Product Docs"

    list_response = client.get("/api/kb", headers=headers)
    assert list_response.status_code == 200, list_response.text
    assert list_response.json()[0]["id"] == kb["id"]
    assert list_response.json()[0]["doc_count"] == 0
    assert list_response.json()[0]["conversation_count"] == 0

    update_response = client.patch(
        "/api/kb/" + kb["id"],
        json={"name": "Updated Docs"},
        headers=headers,
    )
    assert update_response.status_code == 200, update_response.text
    assert update_response.json()["name"] == "Updated Docs"

    delete_response = client.delete("/api/kb/" + kb["id"], headers=headers)
    assert delete_response.status_code == 204, delete_response.text

    list_after_delete = client.get("/api/kb", headers=headers)
    assert list_after_delete.status_code == 200, list_after_delete.text
    assert list_after_delete.json() == []


def test_non_member_cannot_access_knowledge_base(client):
    register_user(client, email="owner@example.com", username="owner")
    owner_tokens = login_user(client, email="owner@example.com")
    owner_headers = auth_headers(owner_tokens)
    kb = client.post(
        "/api/kb",
        json={"name": "Private Docs"},
        headers=owner_headers,
    ).json()

    register_user(client, email="other@example.com", username="other")
    other_tokens = login_user(client, email="other@example.com")

    response = client.get("/api/kb/" + kb["id"], headers=auth_headers(other_tokens))

    assert response.status_code == 403


def test_delete_knowledge_base_removes_related_records(client, monkeypatch, tmp_path):
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(tmp_path / "uploads"))
    register_user(client)
    headers = auth_headers(login_user(client))
    kb = client.post(
        "/api/kb",
        json={"name": "Private Docs"},
        headers=headers,
    ).json()
    uploaded = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={"file": ("faq.txt", b"Refund policy: contact support within 30 days.", "text/plain")},
        headers=headers,
    ).json()

    with client.app.state.testing_session_factory() as db:
        conversation = Conversation(kb_id=kb["id"], user_id=kb["owner_id"], title="Refund")
        db.add(conversation)
        db.flush()
        db.add(Message(conversation_id=conversation.id, role="user", content="Refund?"))
        db.commit()

    delete_response = client.delete("/api/kb/" + kb["id"], headers=headers)

    assert delete_response.status_code == 204, delete_response.text
    with client.app.state.testing_session_factory() as db:
        assert db.execute(select(KnowledgeBaseMember).where(KnowledgeBaseMember.kb_id == kb["id"])).scalars().all() == []
        assert db.execute(select(Document).where(Document.kb_id == kb["id"])).scalars().all() == []
        assert db.execute(select(DocumentChunk).where(DocumentChunk.doc_id == uploaded["id"])).scalars().all() == []
        assert db.execute(select(Conversation).where(Conversation.kb_id == kb["id"])).scalars().all() == []
        assert db.execute(select(Message)).scalars().all() == []
