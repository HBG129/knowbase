"""Knowledge base schemas."""
from pydantic import BaseModel, Field


class KBCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    description: str | None = None


class KBUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = None


class KBResponse(BaseModel):
    id: str
    name: str
    description: str | None
    owner_id: str
    created_at: str
    updated_at: str

    model_config = {"from_attributes": True}


class KBInviteRequest(BaseModel):
    email: str
    role: str = Field(default="viewer", pattern="^(owner|admin|editor|viewer)$")

class KBMemberResponse(BaseModel):
    id: str
    user_id: str
    kb_id: str
    role: str
    joined_at: str
    model_config = {"from_attributes": True}
