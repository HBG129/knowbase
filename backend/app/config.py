"""Application configuration."""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./data/knowbase.db"

    # JWT
    JWT_SECRET_KEY: str = "dev-secret-change-in-prod"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    API_KEY_ENCRYPTION_SECRET: str = ""
    API_KEY_STORAGE_BACKEND: str = "database"

    # OpenAI / LLM
    OPENAI_API_KEY: str = ""
    OPENAI_EMBEDDING_MODEL: str = "text-embedding-3-small"
    OPENAI_CHAT_MODEL: str = "gpt-4o-mini"

    # Zhipu (智谱) — system fallback
    ZHIPU_API_KEY: str = ""
    ZHIPU_BASE_URL: str = "https://open.bigmodel.cn/api/paas/v4"
    ZHIPU_CHAT_MODEL: str = "glm-4-flash"
    ZHIPU_EMBEDDING_MODEL: str = "embedding-2"

    # DeepSeek
    DEEPSEEK_BASE_URL: str = "https://api.deepseek.com"
    DEEPSEEK_CHAT_MODEL: str = "deepseek-chat"

    # Upload
    MAX_UPLOAD_SIZE_MB: int = 50
    UPLOAD_DIR: str = "./data/uploads"

    # CORS
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]

    # OAuth (optional)
    GITHUB_CLIENT_ID: str = ""
    GITHUB_CLIENT_SECRET: str = ""
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # MinIO / S3 Storage
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "minioadmin"
    MINIO_SECRET_KEY: str = "minioadmin123"
    MINIO_BUCKET: str = "knowbase"
    MINIO_SECURE: bool = False

    model_config = {"env_file": "../.env", "env_file_encoding": "utf-8"}


settings = Settings()
