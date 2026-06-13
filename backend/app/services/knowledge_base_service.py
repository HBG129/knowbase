"""Knowledge base business logic."""
import uuid
from sqlalchemy import delete, select, func
from sqlalchemy.orm import Session
from app.models.knowledge_base import KnowledgeBase, KnowledgeBaseMember
from app.models.document import Document, DocumentChunk
from app.models.conversation import Conversation, Message
from app.models.user import User
from app.schemas.knowledge_base import KBCreate, KBUpdate, KBInviteRequest

def create_kb(db: Session, owner_id: str, data: KBCreate) -> KnowledgeBase:
    kb = KnowledgeBase(id=str(uuid.uuid4()), name=data.name, description=data.description, owner_id=owner_id)
    db.add(kb); db.flush()
    db.add(KnowledgeBaseMember(id=str(uuid.uuid4()), kb_id=kb.id, user_id=owner_id, role="owner"))
    db.flush(); return kb

def get_kb(db: Session, kb_id: str) -> KnowledgeBase | None:
    return (db.execute(select(KnowledgeBase).where(KnowledgeBase.id == kb_id))).scalar_one_or_none()

def list_kbs(db: Session, user_id: str) -> list[dict]:
    q = select(KnowledgeBase).join(KnowledgeBaseMember).where(KnowledgeBaseMember.user_id == user_id).order_by(KnowledgeBase.updated_at.desc())
    kbs = list((db.execute(q)).scalars().all())
    # Batch-fetch doc counts
    kb_ids = [kb.id for kb in kbs]
    doc_counts = {}
    conv_counts = {}
    if kb_ids:
        doc_rows = db.execute(
            select(Document.kb_id, func.count(Document.id)).where(Document.kb_id.in_(kb_ids)).group_by(Document.kb_id)
        ).all()
        doc_counts = {r[0]: r[1] for r in doc_rows}
        conv_rows = db.execute(
            select(Conversation.kb_id, func.count(Conversation.id)).where(Conversation.kb_id.in_(kb_ids)).group_by(Conversation.kb_id)
        ).all()
        conv_counts = {r[0]: r[1] for r in conv_rows}
    return [
        {**kb_to_response(kb), "doc_count": doc_counts.get(kb.id, 0), "conversation_count": conv_counts.get(kb.id, 0)}
        for kb in kbs
    ]

def _list_kbs_raw(db: Session, user_id: str) -> list[KnowledgeBase]:
    q = select(KnowledgeBase).join(KnowledgeBaseMember).where(KnowledgeBaseMember.user_id == user_id).order_by(KnowledgeBase.updated_at.desc())
    return list((db.execute(q)).scalars().all())

def update_kb(db: Session, kb_id: str, data: KBUpdate) -> KnowledgeBase | None:
    kb = get_kb(db, kb_id)
    if not kb: return None
    if data.name is not None: kb.name = data.name
    if data.description is not None: kb.description = data.description
    db.flush(); return kb

def delete_kb(db: Session, kb_id: str) -> bool:
    kb = get_kb(db, kb_id)
    if not kb: return False
    conversation_ids = db.execute(select(Conversation.id).where(Conversation.kb_id == kb_id)).scalars().all()
    if conversation_ids:
        db.execute(delete(Message).where(Message.conversation_id.in_(conversation_ids)))
    db.execute(delete(Conversation).where(Conversation.kb_id == kb_id))
    doc_ids = db.execute(select(Document.id).where(Document.kb_id == kb_id)).scalars().all()
    if doc_ids:
        db.execute(delete(DocumentChunk).where(DocumentChunk.doc_id.in_(doc_ids)))
    db.execute(delete(Document).where(Document.kb_id == kb_id))
    db.execute(delete(KnowledgeBaseMember).where(KnowledgeBaseMember.kb_id == kb_id))
    db.delete(kb); db.flush(); return True

def add_member(db: Session, kb_id: str, invited_by: str, data: KBInviteRequest) -> KnowledgeBaseMember:
    user = (db.execute(select(User).where(User.email == data.email))).scalar_one_or_none()
    if not user: raise ValueError("User not found")
    existing = (db.execute(select(KnowledgeBaseMember).where(KnowledgeBaseMember.kb_id == kb_id, KnowledgeBaseMember.user_id == user.id))).scalar_one_or_none()
    if existing: raise ValueError("User is already a member")
    m = KnowledgeBaseMember(id=str(uuid.uuid4()), kb_id=kb_id, user_id=user.id, role=data.role, invited_by=invited_by)
    db.add(m); db.flush(); return m

def list_members(db: Session, kb_id: str) -> list[dict]:
    q = select(KnowledgeBaseMember, User.email, User.username).join(User, KnowledgeBaseMember.user_id == User.id).where(KnowledgeBaseMember.kb_id == kb_id)
    r = db.execute(q)
    return [{"id": m.id, "user_id": m.user_id, "kb_id": m.kb_id, "role": m.role, "email": email, "username": username, "joined_at": m.joined_at.isoformat() if m.joined_at else ""} for m, email, username in r]

def update_member_role(db: Session, kb_id: str, user_id: str, new_role: str) -> bool:
    m = (db.execute(select(KnowledgeBaseMember).where(KnowledgeBaseMember.kb_id == kb_id, KnowledgeBaseMember.user_id == user_id))).scalar_one_or_none()
    if not m: return False
    m.role = new_role; db.flush(); return True

def remove_member(db: Session, kb_id: str, user_id: str) -> bool:
    m = (db.execute(select(KnowledgeBaseMember).where(KnowledgeBaseMember.kb_id == kb_id, KnowledgeBaseMember.user_id == user_id))).scalar_one_or_none()
    if not m: return False
    db.delete(m); db.flush(); return True

def get_user_role(db: Session, kb_id: str, user_id: str) -> str | None:
    m = (db.execute(select(KnowledgeBaseMember).where(KnowledgeBaseMember.kb_id == kb_id, KnowledgeBaseMember.user_id == user_id))).scalar_one_or_none()
    return m.role if m else None

def kb_to_response(kb: KnowledgeBase) -> dict:
    return {"id": kb.id, "name": kb.name, "description": kb.description, "owner_id": kb.owner_id, "created_at": kb.created_at.isoformat() if kb.created_at else "", "updated_at": kb.updated_at.isoformat() if kb.updated_at else ""}
