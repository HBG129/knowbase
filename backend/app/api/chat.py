"""Chat API endpoints with SSE streaming."""
import json
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.conversation import Conversation
from app.schemas.chat import ChatRequest
from app.api.deps import get_current_user
from app.services.chat_service import (
    chat_stream_generator,
    save_assistant_message,
    generate_title_for_conversation,
    list_conversations,
    get_messages,
)
from app.services.knowledge_base_service import get_user_role
from app.services.llm_service import chat_stream as llm_stream

router = APIRouter()


def _conv_to_dict(c):
    return {
        "id": c.id,
        "kb_id": c.kb_id,
        "title": c.title,
        "created_at": c.created_at.isoformat() if c.created_at else "",
        "updated_at": c.updated_at.isoformat() if c.updated_at else "",
    }


@router.post("/{kb_id}/chat")
def chat_endpoint(
    kb_id: str,
    data: ChatRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """SSE streaming chat endpoint — real LLM with RAG context."""
    role = get_user_role(db, kb_id, user.id)
    if role is None:
        raise HTTPException(status_code=403, detail="Access denied")
    if not data.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")

    # Run retrieval + build prompts (sync, inside the request)
    try:
        prep = chat_stream_generator(db, kb_id, user, data.conversation_id, data.message.strip())
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    conv_id = prep["conversation_id"]
    citations = prep["citations"]

    def event_stream():
        full_text = ""
        try:
            # Stream LLM chunks as SSE events
            for chunk in llm_stream(
                user=prep["user"],
                system_prompt=prep["system_prompt"],
                messages=prep["messages"],
            ):
                full_text += chunk
                yield f"data: {json.dumps({'type': 'chunk', 'content': chunk})}\n\n"

            # Save completed message
            save_assistant_message(db, conv_id, full_text, citations)

            # Generate LLM title for new conversations
            title = generate_title_for_conversation(db, prep["user"], conv_id, data.message)
            if not title:
                title = data.message[:60] + ("..." if len(data.message) > 60 else "")
                from sqlalchemy import select as sa_sel
                from app.models.conversation import Conversation as C
                conv = db.execute(sa_sel(C).where(C.id == conv_id)).scalar_one_or_none()
                if conv and conv.title == "New Chat":
                    conv.title = title
                    db.flush()

            # Send final event with citations + conversation_id + title
            yield f"data: {json.dumps({'type': 'done', 'conversation_id': conv_id, 'citations': citations, 'full_text': full_text, 'title': title})}\n\n"

        except Exception as e:
            # Save partial message on error
            if full_text:
                try:
                    save_assistant_message(db, conv_id, full_text, citations)
                except Exception:
                    pass
            yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/{kb_id}/conversations")
def list_convs(
    kb_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    role = get_user_role(db, kb_id, user.id)
    if role is None:
        raise HTTPException(status_code=403, detail="Access denied")
    convs = list_conversations(db, kb_id, user.id)
    return [_conv_to_dict(c) for c in convs]


@router.get("/{kb_id}/conversations/{conv_id}/messages")
def get_msgs(
    kb_id: str,
    conv_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    role = get_user_role(db, kb_id, user.id)
    if role is None:
        raise HTTPException(status_code=403, detail="Access denied")
    conv = db.execute(
        select(Conversation).where(
            Conversation.id == conv_id,
            Conversation.kb_id == kb_id,
            Conversation.user_id == user.id,
        )
    ).scalar_one_or_none()
    if conv is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    msgs = get_messages(db, conv_id)
    return [
        {
            "id": m.id,
            "role": m.role,
            "content": m.content,
            "citations_json": m.citations_json,
            "token_count": m.token_count,
            "created_at": m.created_at.isoformat() if m.created_at else "",
        }
        for m in msgs
    ]


@router.delete("/{kb_id}/conversations/{conv_id}", status_code=204)
def delete_conv(
    kb_id: str,
    conv_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    role = get_user_role(db, kb_id, user.id)
    if role is None:
        raise HTTPException(status_code=403, detail="Access denied")
    from sqlalchemy import delete as sa_delete
    from app.models.conversation import Message as Msg
    conv = db.execute(
        select(Conversation).where(
            Conversation.id == conv_id,
            Conversation.kb_id == kb_id,
            Conversation.user_id == user.id,
        )
    ).scalar_one_or_none()
    if conv is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    db.execute(sa_delete(Msg).where(Msg.conversation_id == conv_id))
    db.delete(conv)
    db.flush()


@router.delete("/{kb_id}/conversations/{conv_id}/messages", status_code=204)
def clear_messages(
    kb_id: str,
    conv_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    role = get_user_role(db, kb_id, user.id)
    if role is None:
        raise HTTPException(status_code=403, detail="Access denied")
    conv = db.execute(
        select(Conversation).where(
            Conversation.id == conv_id,
            Conversation.kb_id == kb_id,
            Conversation.user_id == user.id,
        )
    ).scalar_one_or_none()
    if conv is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    from sqlalchemy import delete as sa_delete
    from app.models.conversation import Message as Msg
    db.execute(sa_delete(Msg).where(Msg.conversation_id == conv_id))
    db.flush()
