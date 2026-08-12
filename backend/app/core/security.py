"""JWT token and password utilities."""
import base64
import hashlib
import uuid
from datetime import datetime, timedelta, timezone
from cryptography.fernet import Fernet, InvalidToken
import jwt
from jwt import InvalidTokenError
from passlib.context import CryptContext
from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt_sha256", "bcrypt"], deprecated=["bcrypt"])
ENCRYPTED_API_KEY_PREFIX = "enc:v1:"


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(
        {"sub": user_id, "exp": expire, "type": "access"},
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )


def create_refresh_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS)
    return jwt.encode(
        {"sub": user_id, "exp": expire, "type": "refresh", "jti": str(uuid.uuid4())},
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )


def decode_token(token: str) -> dict | None:
    try:
        return jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    except InvalidTokenError:
        return None


def _api_key_fernet() -> Fernet:
    secret = settings.API_KEY_ENCRYPTION_SECRET or settings.JWT_SECRET_KEY
    digest = hashlib.sha256(secret.encode("utf-8")).digest()
    key = base64.urlsafe_b64encode(digest)
    return Fernet(key)


def encrypt_api_key(api_key: str) -> str:
    token = _api_key_fernet().encrypt(api_key.encode("utf-8")).decode("utf-8")
    return ENCRYPTED_API_KEY_PREFIX + token


def decrypt_api_key(stored_api_key: str) -> str:
    if not stored_api_key.startswith(ENCRYPTED_API_KEY_PREFIX):
        return stored_api_key
    token = stored_api_key.removeprefix(ENCRYPTED_API_KEY_PREFIX)
    try:
        return _api_key_fernet().decrypt(token.encode("utf-8")).decode("utf-8")
    except InvalidToken as exc:
        raise ValueError("Stored API key cannot be decrypted. Clear it and save the key again.") from exc
