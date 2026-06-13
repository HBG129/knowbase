"""Authentication schemas."""
from pydantic import BaseModel, Field, field_validator


def _validate_email(value: str) -> str:
    email = value.strip()
    local, sep, domain = email.partition("@")
    if (
        not sep
        or not local
        or not domain
        or " " in email
        or "." not in domain
        or domain.startswith(".")
        or domain.endswith(".")
    ):
        raise ValueError("Invalid email")
    return email.lower()


class RegisterRequest(BaseModel):
    email: str
    username: str = Field(min_length=2, max_length=100)
    password: str = Field(min_length=8, max_length=128)

    @field_validator("email")
    @classmethod
    def validate_email(cls, value: str) -> str:
        return _validate_email(value)


class LoginRequest(BaseModel):
    email: str
    password: str

    @field_validator("email")
    @classmethod
    def validate_email(cls, value: str) -> str:
        return _validate_email(value)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: str
    email: str
    username: str
    avatar_url: str | None = None
    email_verified: bool
    role: str
    api_provider: str | None = None
    has_api_key: bool = False
    created_at: str

    model_config = {"from_attributes": True}


class ApiKeyUpdate(BaseModel):
    api_key: str
    api_provider: str  # zhipu / deepseek / openai
