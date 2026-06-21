"""Authentication business logic."""
import uuid
from datetime import datetime, timezone, timedelta
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.config import settings
from app.models.user import User, RefreshToken
from app.schemas.auth import RegisterRequest, TokenResponse, UserResponse
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
)
from app.services.secret_store import delete_api_key, store_api_key


def register(db: Session, data: RegisterRequest) -> User:
    q = select(User).where(User.email == data.email)
    if db.execute(q).scalar_one_or_none() is not None:
        raise ValueError("Email already registered")
    q = select(User).where(User.username == data.username)
    if db.execute(q).scalar_one_or_none() is not None:
        raise ValueError("Username already taken")

    user = User(email=data.email, username=data.username, hashed_password=hash_password(data.password))
    db.add(user)
    db.flush()
    return user


def login(db: Session, email: str, password: str) -> TokenResponse:
    user = db.execute(select(User).where(User.email == email)).scalar_one_or_none()
    if user is None or not verify_password(password, user.hashed_password):
        raise ValueError("Invalid email or password")
    if not user.is_active:
        raise ValueError("Account is deactivated")

    access_token = create_access_token(user.id)
    refresh_token_str = create_refresh_token(user.id)

    refresh = RefreshToken(
        user_id=user.id, token=refresh_token_str,
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS),
    )
    db.add(refresh)
    db.flush()

    return TokenResponse(access_token=access_token, refresh_token=refresh_token_str)


def refresh_access_token(db: Session, token: str) -> TokenResponse:
    stored = db.execute(
        select(RefreshToken).where(RefreshToken.token == token, RefreshToken.revoked == False)
    ).scalar_one_or_none()
    expires_at = stored.expires_at if stored else None
    if expires_at and expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if stored is None or expires_at < datetime.now(timezone.utc):
        raise ValueError("Invalid or expired refresh token")

    stored.revoked = True
    access_token = create_access_token(stored.user_id)
    new_refresh_str = create_refresh_token(stored.user_id)

    new_refresh = RefreshToken(
        user_id=stored.user_id, token=new_refresh_str,
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS),
    )
    db.add(new_refresh)
    db.flush()

    return TokenResponse(access_token=access_token, refresh_token=new_refresh_str)


def user_to_response(user: User) -> UserResponse:
    return UserResponse(
        id=user.id, email=user.email, username=user.username,
        avatar_url=user.avatar_url, email_verified=user.email_verified,
        role=user.role, api_provider=user.api_provider, has_api_key=bool(user.api_key),
        created_at=user.created_at.isoformat() if user.created_at else "",
    )


def set_user_api_key(db: Session, user: User, api_key: str, provider: str) -> User:
    valid_providers = {"zhipu", "deepseek", "openai"}
    if provider not in valid_providers:
        raise ValueError(f"Invalid provider. Choose: {', '.join(sorted(valid_providers))}")
    user.api_key = store_api_key(user.id, api_key)
    user.api_provider = provider
    db.flush()
    return user


def clear_user_api_key(db: Session, user: User) -> User:
    delete_api_key(user.api_key)
    user.api_key = None
    user.api_provider = None
    db.flush()
    return user
