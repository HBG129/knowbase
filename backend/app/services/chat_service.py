"""Chat service with real RAG + LLM streaming integration."""
import uuid
import json
from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.config import settings
from app.models.user import User
from app.models.conversation import Conversation, Message
from app.services.retrieval_service import hybrid_search
from app.services.llm_service import chat_stream as llm_chat_stream, chat_sync as llm_chat_sync


def create_conversation(db: Session, kb_id: str, user_id: str, title: str = "New Chat") -> Conversation:
    conv = Conversation(id=str(uuid.uuid4()), kb_id=kb_id, user_id=user_id, title=title)
    db.add(conv)
    db.flush()
    return conv


def get_or_create_conversation(db: Session, kb_id: str, user_id: str, conversation_id: str | None) -> Conversation:
    if conversation_id:
        conv = db.execute(
            select(Conversation).where(
                Conversation.id == conversation_id,
                Conversation.user_id == user_id,
                Conversation.kb_id == kb_id,
            )
        ).scalar_one_or_none()
        if conv:
            return conv
        raise ValueError("Conversation not found")
    return create_conversation(db, kb_id, user_id)


def list_conversations(db: Session, kb_id: str, user_id: str) -> list[Conversation]:
    r = db.execute(
        select(Conversation)
        .where(Conversation.kb_id == kb_id, Conversation.user_id == user_id)
        .order_by(Conversation.updated_at.desc())
    )
    return list(r.scalars().all())


def get_messages(db: Session, conversation_id: str) -> list[Message]:
    r = db.execute(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.asc())
    )
    return list(r.scalars().all())


def get_chat_history(db: Session, conversation_id: str) -> list[dict]:
    """Retrieve recent messages as OpenAI-format chat history."""
    msgs = get_messages(db, conversation_id)
    history = []
    for m in msgs[-20:]:  # sliding window: last 20 messages
        history.append({"role": m.role, "content": m.content})
    return history


def build_system_prompt(context: str, kb_name: str = "") -> str:
    """Build the system prompt with retrieved context."""
    base = (
        "你是一个知识库 AI 助手。请用与用户相同的语言回答。用户用中文问就用中文答，用英文问就用英文答。\n"
        "You are a knowledge base AI assistant. Respond in the same language the user uses.\n\n"
        "规则 / Rules:\n"
        "- 基于下面的参考上下文回答。如果上下文中没有相关信息，如实告知。\n"
        "- Answer based on the reference context below. If no relevant info, say so honestly.\n"
        "- 引用来源时标注如 [Chunk 0], [Chunk 2]。\n"
        "- 使用 Markdown 格式化回复（标题、列表、代码块）。\n"
        "- 保持专业、简洁、有帮助。\n\n"
    )
    if context.strip():
        return base + f"**参考上下文 / Reference Context:**\n\n{context}"
    return base + "**注意:** 知识库中未找到与查询相关的文档。建议上传相关文档后重试。\n**Note:** No relevant documents found. Try uploading related documents."


def chat_stream_generator(
    db: Session,
    kb_id: str,
    user: User,
    conversation_id: str | None,
    user_message: str,
) -> dict:
    """
    Run RAG pipeline and return a generator config for SSE streaming.
    Returns metadata dict with conversation_id and the generator.
    """
    conv = get_or_create_conversation(db, kb_id, user.id, conversation_id)

    # Store user message
    user_msg = Message(
        id=str(uuid.uuid4()),
        conversation_id=conv.id,
        role="user",
        content=user_message,
        token_count=len(user_message) // 4,
    )
    db.add(user_msg)
    db.flush()

    # Retrieve context
    chunks = hybrid_search(db, kb_id, user_message, top_k=6, user=user)
    context = "\n\n---\n\n".join(
        f"[Chunk {c['chunk_index']}] (doc: {c['doc_id'][:8]}...) {c['content']}"
        for c in chunks
    )

    # Build prompts
    system_prompt = build_system_prompt(context)
    history = get_chat_history(db, conv.id)
    history.append({"role": "user", "content": user_message})

    # Prepare citations
    citations = [
        {"doc_id": c["doc_id"], "doc_filename": c.get("doc_filename", c["doc_id"][:12] + "…"), "chunk_index": c["chunk_index"], "snippet": c["content"][:150]}
        for c in chunks[:5]
    ]

    return {
        "conversation_id": conv.id,
        "system_prompt": system_prompt,
        "messages": history,
        "user": user,
        "citations": citations,
    }


def generate_title_for_conversation(db: Session, user: User, conv_id: str, first_message: str) -> str | None:
    """Generate a short title for the conversation using LLM."""
    try:
        prompt = f"Generate a very short title (3-6 words, in the same language as this message) for a conversation that starts with: \"{first_message[:200]}\". Return ONLY the title, no quotes, no explanation."
        title = llm_chat_sync(user, "You are a helpful assistant that generates concise conversation titles.", [{"role": "user", "content": prompt}], temperature=0.2)
        title = title.strip().strip('"').strip("'").strip()
        if title and len(title) <= 80:
            conv = db.execute(select(Conversation).where(Conversation.id == conv_id)).scalar_one_or_none()
            if conv:
                conv.title = title
                db.flush()
                return title
    except Exception:
        pass
    return None


def save_assistant_message(
    db: Session,
    conversation_id: str,
    content: str,
    citations: list[dict],
) -> Message:
    """Save the completed assistant message to database."""
    msg = Message(
        id=str(uuid.uuid4()),
        conversation_id=conversation_id,
        role="assistant",
        content=content,
        citations_json=json.dumps(citations),
        token_count=len(content) // 4,
    )
    db.add(msg)
    # Touch conversation timestamp
    conv = db.execute(
        select(Conversation).where(Conversation.id == conversation_id)
    ).scalar_one_or_none()
    if conv:
        conv.updated_at = datetime.now(timezone.utc)
    db.flush()
    return msg
