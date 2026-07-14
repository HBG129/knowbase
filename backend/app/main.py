"""KnowBase FastAPI Application."""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import init_db
import app.models  # noqa: F401
from app.api.auth import router as auth_router
from app.api.knowledge_base import router as kb_router
from app.api.document import router as doc_router
from app.api.chat import router as chat_router
from app.api.analysis import router as analysis_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


def create_app() -> FastAPI:
    app = FastAPI(title="KnowBase API", version="0.1.0", lifespan=lifespan)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    return app


app = create_app()
app.include_router(auth_router, prefix="/api/auth", tags=["auth"])
app.include_router(kb_router, prefix="/api/kb", tags=["knowledge_base"])
app.include_router(doc_router, prefix="/api/kb", tags=["documents"])
app.include_router(chat_router, prefix="/api/kb", tags=["chat"])
app.include_router(analysis_router, prefix="/api/kb", tags=["analysis"])


@app.get("/api/health")
async def health():
    return {"status": "ok"}
