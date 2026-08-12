"""Document upload and management API."""
import uuid, os
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy import delete, select
from sqlalchemy.orm import Session
from app.config import settings
from app.database import get_db
from app.models.user import User
from app.models.document import Document, DocumentChunk
from app.models.analysis import AnalysisRun
from app.api.deps import get_current_user
from app.services.knowledge_base_service import get_user_role
from app.services.ingestion_service import ingest_document

router = APIRouter()


@router.post("/{kb_id}/documents", status_code=201)
def upload_doc(kb_id: str, file: UploadFile = File(...), user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    role = get_user_role(db, kb_id, user.id)
    if role not in ("owner", "admin", "editor"):
        raise HTTPException(403, "Only owner/admin/editor can upload documents")

    filename = os.path.basename((file.filename or "").replace("\\", "/"))
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    if ext not in ("pdf", "docx", "doc", "md", "markdown", "txt", "csv"):
        raise HTTPException(400, f"Unsupported file type: {ext}")

    content = file.file.read()
    if len(content) == 0:
        raise HTTPException(400, "File is empty")
    if len(content) > settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024:
        raise HTTPException(400, f"File exceeds {settings.MAX_UPLOAD_SIZE_MB}MB limit")

    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    file_id = str(uuid.uuid4())
    file_path = os.path.join(settings.UPLOAD_DIR, f"{file_id}_{filename}")

    with open(file_path, "wb") as f:
        f.write(content)

    doc = Document(id=str(uuid.uuid4()), kb_id=kb_id, filename=filename, file_type=ext, file_size=len(content), file_path=file_path, uploaded_by=user.id)
    db.add(doc)
    db.flush()

    try:
        ingest_document(db, doc, user)
    except Exception as e:
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(400, f"Document ingestion failed: {e}")

    return {"id": doc.id, "filename": doc.filename, "file_type": doc.file_type, "file_size": doc.file_size, "status": doc.status, "chunk_count": doc.chunk_count, "created_at": doc.created_at.isoformat() if doc.created_at else ""}


@router.get("/{kb_id}/documents")
def list_docs(kb_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    role = get_user_role(db, kb_id, user.id)
    if role is None:
        raise HTTPException(403, "Access denied")
    q = select(Document).where(Document.kb_id == kb_id).order_by(Document.created_at.desc())
    r = db.execute(q)
    docs = r.scalars().all()
    return [{"id": d.id, "filename": d.filename, "file_type": d.file_type, "file_size": d.file_size, "status": d.status, "chunk_count": d.chunk_count, "error_message": d.error_message, "created_at": d.created_at.isoformat() if d.created_at else ""} for d in docs]


@router.delete("/{kb_id}/documents/{doc_id}", status_code=204)
def delete_doc(kb_id: str, doc_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    role = get_user_role(db, kb_id, user.id)
    if role not in ("owner", "admin"):
        raise HTTPException(403, "Only owner/admin can delete documents")
    q = select(Document).where(Document.id == doc_id, Document.kb_id == kb_id)
    doc = db.execute(q).scalar_one_or_none()
    if not doc:
        raise HTTPException(404, "Document not found")
    if os.path.exists(doc.file_path):
        os.remove(doc.file_path)
    db.execute(delete(AnalysisRun).where(AnalysisRun.doc_id == doc.id))
    db.execute(delete(DocumentChunk).where(DocumentChunk.doc_id == doc.id))
    db.delete(doc)
    db.flush()
