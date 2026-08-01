"""Hybrid retrieval: BM25 keyword + vector + RRF fusion."""
import json
import math
from collections import Counter
from sqlalchemy import select, func as sa_func
from sqlalchemy.orm import Session
from app.config import settings
from app.models.document import Document, DocumentChunk
from app.models.user import User
from app.services.llm_service import embed_query, embed_texts

# ── lightweight tokenizer (English + CJK) ──
def _tokenize(text: str) -> list[str]:
    tokens = []
    buf = ""
    for ch in text:
        if '\u4e00' <= ch <= '\u9fff' or '\u3400' <= ch <= '\u4dbf':
            if buf:
                tokens.append(buf.lower()); buf = ""
            tokens.append(ch)
        elif ch.isalpha() or ch.isdigit():
            buf += ch
        else:
            if buf:
                tokens.append(buf.lower()); buf = ""
    if buf:
        tokens.append(buf.lower())
    return [t for t in tokens if len(t) > 0]

# ── BM25 scorer ──
def _bm25_score(
    query_tokens: list[str],
    doc_tokens: list[str],
    doc_freqs: dict[str, int],  # token -> how many docs contain it
    total_docs: int,
    avg_doc_length: float | None = None,
    k1: float = 1.2, b: float = 0.75,
) -> float:
    if not query_tokens or not doc_tokens:
        return 0.0
    avgdl = avg_doc_length or len(doc_tokens)
    dl = len(doc_tokens)
    score = 0.0
    for qt in query_tokens:
        n = doc_freqs.get(qt, 0)
        if n == 0:
            continue
        idf = math.log(1 + (total_docs - n + 0.5) / (n + 0.5))
        tf = doc_tokens.count(qt)
        numerator = tf * (k1 + 1)
        denominator = tf + k1 * (1 - b + b * dl / avgdl)
        score += idf * numerator / denominator
    return score

def keyword_search_bm25(db: Session, kb_id: str, query: str, top_k: int = 20) -> list[DocumentChunk]:
    """BM25 keyword search over document chunks."""
    all_chunks = db.execute(
        select(DocumentChunk).join(Document).where(Document.kb_id == kb_id).limit(500)
    ).scalars().all()
    if not all_chunks:
        return []
    query_tokens = _tokenize(query)
    if not query_tokens:
        return all_chunks[:top_k]
    # Pre-tokenize all chunks, compute doc frequencies
    tokenized = []
    doc_freqs: dict[str, int] = {}
    for chunk in all_chunks:
        tokens = _tokenize(chunk.content)
        tokenized.append((chunk, tokens))
        for t in set(tokens):
            doc_freqs[t] = doc_freqs.get(t, 0) + 1
    total_docs = len(tokenized)
    avg_doc_length = sum(len(tokens) for _, tokens in tokenized) / total_docs
    scored = []
    for chunk, tokens in tokenized:
        s = _bm25_score(query_tokens, tokens, doc_freqs, total_docs, avg_doc_length)
        if s > 0:
            scored.append((chunk, s))
    scored.sort(key=lambda x: x[1], reverse=True)
    return [c for c, _ in scored[:top_k]]


def keyword_search(db: Session, kb_id: str, query: str, top_k: int = 20) -> list[DocumentChunk]:
    """Fallback: SQL LIKE search (used as complement)."""
    q = (
        select(DocumentChunk)
        .join(Document)
        .where(Document.kb_id == kb_id, DocumentChunk.content.contains(query))
        .order_by(sa_func.length(DocumentChunk.content))
        .limit(top_k)
    )
    r = db.execute(q)
    return list(r.scalars().all())


def vector_search(db: Session, kb_id: str, query_embedding: list[float], top_k: int = 20) -> list[DocumentChunk]:
    """Vector search with pgvector (production) or app-level cosine (dev/SQLite)."""
    if not query_embedding:
        return []
    try:
        from sqlalchemy import text
        q = text("""
            SELECT dc.*, 1 - (dc.embedding <=> CAST(:embedding AS vector)) AS _similarity
            FROM document_chunks dc
            JOIN documents d ON d.id = dc.doc_id
            WHERE d.kb_id = :kb_id AND dc.embedding IS NOT NULL
            ORDER BY dc.embedding <=> CAST(:embedding AS vector)
            LIMIT :top_k
        """)
        r = db.execute(q, {"embedding": str(query_embedding), "kb_id": kb_id, "top_k": top_k})
        rows = r.fetchall()
        chunks = []
        for row in rows:
            chunk = DocumentChunk(id=row.id, doc_id=row.doc_id, chunk_index=row.chunk_index, content=row.content, token_count=row.token_count)
            chunks.append(chunk)
        if chunks:
            return chunks
    except Exception:
        pass
    q = select(DocumentChunk).join(Document).where(Document.kb_id == kb_id, DocumentChunk.embedding_json.isnot(None)).limit(200)
    r = db.execute(q)
    candidates = list(r.scalars().all())
    scored = []
    for chunk in candidates:
        try:
            vec = json.loads(chunk.embedding_json)
            dot = sum(a * b for a, b in zip(query_embedding, vec))
            scored.append((chunk, dot))
        except Exception:
            pass
    scored.sort(key=lambda x: x[1], reverse=True)
    return [c for c, _ in scored[:top_k]]


def _ngram_vector(text: str, n: int = 2, vocab: dict[str, int] | None = None) -> tuple[Counter, list[float] | None]:
    """Build character n-gram frequency vector. If vocab provided, return dense float vector."""
    chars = [ch for ch in text if ch.strip()]
    ngrams = [''.join(chars[i:i+n]) for i in range(len(chars)-n+1)]
    c = Counter(ngrams)
    if vocab:
        vec = [0.0] * len(vocab)
        for ng, idx in vocab.items():
            vec[idx] = c.get(ng, 0)
        # Normalize
        norm = math.sqrt(sum(v*v for v in vec))
        if norm > 0:
            vec = [v / norm for v in vec]
        return c, vec
    return c, None


def local_vector_search(db: Session, kb_id: str, query: str, top_k: int = 20) -> list[DocumentChunk]:
    """Local fallback: character bigram cosine similarity (no API needed)."""
    chunks_q = select(DocumentChunk).join(Document).where(Document.kb_id == kb_id).limit(500)
    all_chunks = list(db.execute(chunks_q).scalars().all())
    if not all_chunks:
        return []
    # Build vocab from all chunk bigrams
    vocab: dict[str, int] = {}
    for chunk in all_chunks:
        chars = [c for c in chunk.content if c.strip()]
        for i in range(len(chars) - 1):
            bg = chars[i] + chars[i + 1]
            if bg not in vocab:
                vocab[bg] = len(vocab)
    if not vocab:
        return []
    _, q_vec = _ngram_vector(query, 2, vocab)
    if q_vec is None:
        return all_chunks[:top_k]
    scored = []
    for chunk in all_chunks:
        _, c_vec = _ngram_vector(chunk.content, 2, vocab)
        if c_vec:
            dot = sum(a * b for a, b in zip(q_vec, c_vec))
            scored.append((chunk, dot))
    scored.sort(key=lambda x: x[1], reverse=True)
    return [c for c, _ in scored[:top_k]]


def hybrid_search(db: Session, kb_id: str, query: str, top_k: int = 10, user: User | None = None) -> list[dict]:
    """RRF-fused hybrid search: BM25 + vector (API or local fallback)."""
    kw_results = keyword_search_bm25(db, kb_id, query, top_k * 2)
    if len(kw_results) < 3:
        like_results = keyword_search(db, kb_id, query, top_k)
        seen = {c.id for c in kw_results}
        for c in like_results:
            if c.id not in seen:
                kw_results.append(c)
    
    # Try API embedding first, fall back to local n-gram
    vec = []
    try:
        vec = embed_query(user, query)
    except Exception:
        pass
    
    if vec:
        vec_results = vector_search(db, kb_id, vec, top_k * 2)
    else:
        vec_results = local_vector_search(db, kb_id, query, top_k * 2)


    scores: dict[str, float] = {}
    k = 60
    for rank, chunk in enumerate(kw_results):
        scores[chunk.id] = scores.get(chunk.id, 0) + 1.0 / (k + rank + 1)
    for rank, chunk in enumerate(vec_results):
        scores[chunk.id] = scores.get(chunk.id, 0) + 1.0 / (k + rank + 1)

    merged = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    all_chunks = {c.id: c for c in kw_results}
    for c in vec_results:
        if c.id not in all_chunks:
            all_chunks[c.id] = c

    doc_ids = {chunk.doc_id for chunk_id, _ in merged[:top_k] if (chunk := all_chunks.get(chunk_id))}
    doc_filenames = {}
    if doc_ids:
        docs = db.execute(select(Document).where(Document.id.in_(doc_ids))).scalars().all()
        doc_filenames = {d.id: d.filename for d in docs}

    results = []
    for chunk_id, _ in merged[:top_k]:
        chunk = all_chunks.get(chunk_id)
        if chunk:
            results.append({
                "chunk_id": chunk.id,
                "content": chunk.content,
                "doc_id": chunk.doc_id,
                "doc_filename": doc_filenames.get(chunk.doc_id, chunk.doc_id[:12] + "…"),
                "chunk_index": chunk.chunk_index,
                "score": round(scores[chunk_id], 4),
            })
    return results


def embed_chunks_for_document(user: User | None, chunks: list[str]) -> list[list[float]]:
    if not chunks:
        return []
    try:
        return embed_texts(user, chunks)
    except Exception:
        return []
