"""Document ingestion: parse, chunk, embed, store."""
import uuid
import os
import json
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.config import settings
from app.models.document import Document, DocumentChunk
from app.models.user import User
from app.services.llm_service import embed_texts

CHUNK_SIZE = 800
CHUNK_OVERLAP = 150

try:
    from langchain_text_splitters import RecursiveCharacterTextSplitter
    _HAS_LANGCHAIN = True
except ImportError:
    _HAS_LANGCHAIN = False

def parse_document(file_path: str, file_type: str) -> str:
    if file_type == "pdf":
        import fitz
        doc = fitz.open(file_path)
        text = "\n".join(page.get_text() for page in doc)
        doc.close()
        return text
    elif file_type == "docx":
        from docx import Document as DocxDoc
        doc = DocxDoc(file_path)
        return "\n".join(p.text for p in doc.paragraphs if p.text)
    elif file_type == "doc":
        # Try python-docx first (some .doc are actually .docx renamed)
        try:
            from docx import Document as DocxDoc
            doc = DocxDoc(file_path)
            return "\n".join(p.text for p in doc.paragraphs if p.text)
        except Exception:
            pass
        # Try olefile for old binary .doc
        try:
            import olefile, re
            ole = olefile.OleFileIO(file_path)
            text_data = b""
            for stream_name in ["WordDocument", "1Table", "0Table"]:
                if ole.exists(stream_name):
                    text_data += ole.openstream(stream_name).read()
            ole.close()
            # Extract readable text chunks (both ASCII and UTF-16LE)
            decoded = text_data.decode("utf-16-le", errors="ignore")
            chunks = re.findall(r'[\u4e00-\u9fff\u3400-\u4dbf\u3000-\u303f\uff00-\uffefa-zA-Z0-9\s.,!?;:()\[\]{}\-+=@#$%^&*/\'\"\\]{3,}', decoded)
            text = "\n".join(ch for ch in chunks if not ch.isspace() and len(ch) > 2)
            if len(text) > 50:
                return text
        except Exception:
            pass
        raise ValueError(
            "无法解析旧版 .doc 文件。请用 Microsoft Word 另存为 .docx 格式后重新上传。"
        )
    elif file_type in ("md", "markdown", "txt"):
        with open(file_path, encoding="utf-8") as f:
            return f.read()
    elif file_type == "csv":
        return open(file_path, encoding="utf-8").read()
    else:
        raise ValueError(f"Unsupported file type: {file_type}")


def _split_text_simple(text: str, chunk_size: int = 800, overlap: int = 150) -> list[str]:
    """Fallback text splitter when langchain is not available."""
    chunks = []
    start = 0
    while start < len(text):
        end = min(start + chunk_size, len(text))
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks


def chunk_and_store(db: Session, doc: Document, text: str) -> int:
    if _HAS_LANGCHAIN:
        splitter = RecursiveCharacterTextSplitter(
            chunk_size=CHUNK_SIZE, chunk_overlap=CHUNK_OVERLAP,
            separators=["\n\n", "\n", ". ", " ", ""]
        )
        chunks = splitter.split_text(text)
    else:
        chunks = _split_text_simple(text, CHUNK_SIZE, CHUNK_OVERLAP)

    for i, chunk in enumerate(chunks):
        dc = DocumentChunk(
            id=str(uuid.uuid4()), doc_id=doc.id, chunk_index=i,
            content=chunk, token_count=len(chunk) // 4
        )
        db.add(dc)

    doc.status = "completed"
    doc.chunk_count = len(chunks)
    db.flush()
    return len(chunks)


def ingest_document(db: Session, doc: Document, user: User | None = None) -> int:
    try:
        doc.status = "processing"
        db.flush()
        text = parse_document(doc.file_path, doc.file_type)
        count = chunk_and_store(db, doc, text)

        # Embed chunks
        chunks = db.execute(
            select(DocumentChunk).where(DocumentChunk.doc_id == doc.id).order_by(DocumentChunk.chunk_index)
        ).scalars().all()
        if chunks:
            chunk_texts = [c.content for c in chunks]
            try:
                embeddings = embed_texts(user, chunk_texts)
                for chunk, vec in zip(chunks, embeddings):
                    chunk.embedding_json = json.dumps(vec)
                db.flush()
            except Exception as e:
                # Embedding failed but chunks are stored — user can still keyword-search
                doc.error_message = f"Embedding failed: {e}"
                db.flush()

        return count
    except Exception as e:
        doc.status = "failed"
        doc.error_message = str(e)
        db.flush()
        raise
