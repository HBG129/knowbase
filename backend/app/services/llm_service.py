"""Multi-provider LLM service: user key → system Zhipu fallback → OpenAI fallback."""
from openai import OpenAI
from app.config import settings
from app.core.security import decrypt_api_key
from app.models.user import User


def _user_api_key(user: User) -> str:
    return decrypt_api_key(user.api_key or "")


def _resolve_llm(user: User | None = None) -> dict:
    """Resolve LLM config. Priority: user key > system Zhipu > system OpenAI."""
    if user and user.api_key and user.api_provider:
        api_key = _user_api_key(user)
        if user.api_provider == "zhipu":
            return {"api_key": api_key, "base_url": settings.ZHIPU_BASE_URL, "model": settings.ZHIPU_CHAT_MODEL}
        elif user.api_provider == "deepseek":
            return {"api_key": api_key, "base_url": settings.DEEPSEEK_BASE_URL, "model": settings.DEEPSEEK_CHAT_MODEL}
        elif user.api_provider == "openai":
            return {"api_key": api_key, "base_url": "https://api.openai.com/v1", "model": settings.OPENAI_CHAT_MODEL}
    if settings.ZHIPU_API_KEY:
        return {"api_key": settings.ZHIPU_API_KEY, "base_url": settings.ZHIPU_BASE_URL, "model": settings.ZHIPU_CHAT_MODEL}
    if settings.OPENAI_API_KEY:
        return {"api_key": settings.OPENAI_API_KEY, "base_url": "https://api.openai.com/v1", "model": settings.OPENAI_CHAT_MODEL}
    raise ValueError("No LLM API key configured. Set your API key in Settings, or configure a system fallback key.")


def _resolve_embedding(user: User | None = None) -> dict:
    """Resolve embedding config. Same priority as LLM."""
    if user and user.api_key and user.api_provider:
        api_key = _user_api_key(user)
        if user.api_provider == "zhipu":
            return {"api_key": api_key, "base_url": settings.ZHIPU_BASE_URL, "model": settings.ZHIPU_EMBEDDING_MODEL}
        elif user.api_provider == "deepseek":
            return {"api_key": api_key, "base_url": settings.DEEPSEEK_BASE_URL, "model": settings.OPENAI_EMBEDDING_MODEL}
        elif user.api_provider == "openai":
            return {"api_key": api_key, "base_url": "https://api.openai.com/v1", "model": settings.OPENAI_EMBEDDING_MODEL}
    if settings.ZHIPU_API_KEY:
        return {"api_key": settings.ZHIPU_API_KEY, "base_url": settings.ZHIPU_BASE_URL, "model": settings.ZHIPU_EMBEDDING_MODEL}
    if settings.OPENAI_API_KEY:
        return {"api_key": settings.OPENAI_API_KEY, "base_url": "https://api.openai.com/v1", "model": settings.OPENAI_EMBEDDING_MODEL}
    raise ValueError("No Embedding API key configured.")


def chat_stream(user: User | None, system_prompt: str, messages: list[dict], temperature: float = 0.3):
    """Generator that yields content chunks from LLM streaming response."""
    cfg = _resolve_llm(user)
    client = OpenAI(api_key=cfg["api_key"], base_url=cfg["base_url"])
    response = client.chat.completions.create(
        model=cfg["model"],
        messages=[{"role": "system", "content": system_prompt}] + messages,
        temperature=temperature,
        max_tokens=2048,
        stream=True,
    )
    for chunk in response:
        delta = chunk.choices[0].delta if chunk.choices else None
        if delta and delta.content:
            yield delta.content


def chat_sync(user: User | None, system_prompt: str, messages: list[dict], temperature: float = 0.3) -> str:
    """Non-streaming chat for simple completions."""
    cfg = _resolve_llm(user)
    client = OpenAI(api_key=cfg["api_key"], base_url=cfg["base_url"])
    response = client.chat.completions.create(
        model=cfg["model"],
        messages=[{"role": "system", "content": system_prompt}] + messages,
        temperature=temperature,
        max_tokens=2048,
        stream=False,
    )
    return response.choices[0].message.content or ""


def embed_texts(user: User | None, texts: list[str]) -> list[list[float]]:
    """Generate embeddings for a list of texts."""
    cfg = _resolve_embedding(user)
    client = OpenAI(api_key=cfg["api_key"], base_url=cfg["base_url"])
    response = client.embeddings.create(model=cfg["model"], input=texts)
    return [d.embedding for d in response.data]


def embed_query(user: User | None, text: str) -> list[float]:
    """Generate embedding for a single query text."""
    return embed_texts(user, [text])[0]
