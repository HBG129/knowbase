"""Authentication API endpoints."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.schemas.auth import RegisterRequest, LoginRequest, RefreshRequest, TokenResponse, UserResponse, ApiKeyUpdate
from app.services.auth_service import register, login, refresh_access_token, user_to_response, set_user_api_key, clear_user_api_key
from app.api.deps import get_current_user

router = APIRouter()


@router.post("/register", response_model=UserResponse, status_code=201)
def register_endpoint(data: RegisterRequest, db: Session = Depends(get_db)):
    try:
        user = register(db, data)
        return user_to_response(user)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=TokenResponse)
def login_endpoint(data: LoginRequest, db: Session = Depends(get_db)):
    try:
        return login(db, data.email, data.password)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/refresh", response_model=TokenResponse)
def refresh_endpoint(data: RefreshRequest, db: Session = Depends(get_db)):
    try:
        return refresh_access_token(db, data.refresh_token)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.get("/me", response_model=UserResponse)
def me_endpoint(current_user: User = Depends(get_current_user)):
    return user_to_response(current_user)


@router.put("/me/api-key", response_model=UserResponse)
def set_api_key(data: ApiKeyUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        updated = set_user_api_key(db, user, data.api_key, data.api_provider)
        return user_to_response(updated)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/me/api-key", response_model=UserResponse)
def delete_api_key(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    updated = clear_user_api_key(db, user)
    return user_to_response(updated)
