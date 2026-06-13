"""Database connection and session management."""
from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from app.config import settings

# Sync engine for dev (avoids greenlet dependency on Windows)
DATABASE_URL_SYNC = settings.DATABASE_URL.replace("+aiosqlite", "").replace("sqlite+", "sqlite:///")
engine = create_engine(DATABASE_URL_SYNC, echo=False, pool_pre_ping=True)
SessionLocal = sessionmaker(engine, class_=Session, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def init_db():
    Base.metadata.create_all(bind=engine)
