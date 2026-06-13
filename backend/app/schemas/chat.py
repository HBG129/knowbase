"""Chat schemas."""
from pydantic import BaseModel


class ChatRequest(BaseModel):
    message: str
    conversation_id: str | None = None


class ConversationResponse(BaseModel):
    id: str
    kb_id: str
    title: str
    created_at: str
    updated_at: str
    model_config = {"from_attributes": True}


class ConversationListResponse(BaseModel):
    conversations: list[ConversationResponse]
    total: int


class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    role: str
    content: str
    citations: list[dict] | None = None
    token_count: int
    created_at: str
    model_config = {"from_attributes": True}
