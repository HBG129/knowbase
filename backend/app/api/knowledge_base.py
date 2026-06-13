"""Knowledge base API endpoints."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.schemas.knowledge_base import KBCreate, KBUpdate, KBInviteRequest
from app.api.deps import get_current_user
from app.services import knowledge_base_service as kb_svc

router = APIRouter()


@router.post("", status_code=201)
def create_ep(data: KBCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return kb_svc.kb_to_response(kb_svc.create_kb(db, user.id, data))


@router.get("")
def list_ep(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return kb_svc.list_kbs(db, user.id)


@router.get("/{kb_id}")
def get_ep(kb_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not kb_svc.get_user_role(db, kb_id, user.id):
        raise HTTPException(403, "Access denied")
    kb = kb_svc.get_kb(db, kb_id)
    if not kb:
        raise HTTPException(404, "Not found")
    return kb_svc.kb_to_response(kb)


@router.patch("/{kb_id}")
def update_ep(kb_id: str, data: KBUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    role = kb_svc.get_user_role(db, kb_id, user.id)
    if role not in ("owner", "admin"):
        raise HTTPException(403, "Only owner/admin can update")
    kb = kb_svc.update_kb(db, kb_id, data)
    if not kb:
        raise HTTPException(404, "Not found")
    return kb_svc.kb_to_response(kb)


@router.delete("/{kb_id}", status_code=204)
def delete_ep(kb_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if kb_svc.get_user_role(db, kb_id, user.id) != "owner":
        raise HTTPException(403, "Only owner can delete")
    kb_svc.delete_kb(db, kb_id)


@router.get("/{kb_id}/members")
def members_ep(kb_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not kb_svc.get_user_role(db, kb_id, user.id):
        raise HTTPException(403, "Access denied")
    return kb_svc.list_members(db, kb_id)


@router.post("/{kb_id}/members", status_code=201)
def invite_ep(kb_id: str, data: KBInviteRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    role = kb_svc.get_user_role(db, kb_id, user.id)
    if role not in ("owner", "admin"):
        raise HTTPException(403, "Only owner/admin can invite")
    if data.role == "owner":
        raise HTTPException(400, "Owner role cannot be assigned")
    try:
        return kb_svc.add_member(db, kb_id, user.id, data)
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.patch("/{kb_id}/members/{member_user_id}")
def update_member_ep(kb_id: str, member_user_id: str, data: dict, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if kb_svc.get_user_role(db, kb_id, user.id) != "owner":
        raise HTTPException(403, "Only owner")
    current_role = kb_svc.get_user_role(db, kb_id, member_user_id)
    if current_role is None:
        raise HTTPException(404, "Member not found")
    if current_role == "owner":
        raise HTTPException(403, "Owner role cannot be changed")
    new_role = data.get("role")
    if new_role not in ("admin", "editor", "viewer"):
        raise HTTPException(400, "Role must be admin, editor, or viewer")
    return kb_svc.update_member_role(db, kb_id, member_user_id, new_role)


@router.delete("/{kb_id}/members/{member_user_id}", status_code=204)
def remove_member_ep(kb_id: str, member_user_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if kb_svc.get_user_role(db, kb_id, user.id) not in ("owner", "admin"):
        raise HTTPException(403, "Only owner/admin")
    if kb_svc.get_user_role(db, kb_id, member_user_id) == "owner":
        raise HTTPException(403, "Owner cannot be removed")
    kb_svc.remove_member(db, kb_id, member_user_id)
