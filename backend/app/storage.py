"""MinIO / S3-compatible storage client."""
from io import BytesIO
from minio import Minio
from minio.error import S3Error
from app.config import settings

_client: Minio | None = None


def get_minio() -> Minio:
    global _client
    if _client is None:
        _client = Minio(
            settings.MINIO_ENDPOINT,
            access_key=settings.MINIO_ACCESS_KEY,
            secret_key=settings.MINIO_SECRET_KEY,
            secure=settings.MINIO_SECURE,
        )
        bucket = settings.MINIO_BUCKET
        if not _client.bucket_exists(bucket):
            _client.make_bucket(bucket)
    return _client


async def upload_file(object_name: str, data: bytes, content_type: str) -> str:
    client = get_minio()
    client.put_object(
        settings.MINIO_BUCKET,
        object_name,
        BytesIO(data),
        length=len(data),
        content_type=content_type,
    )
    return object_name


async def get_file(object_name: str) -> bytes | None:
    client = get_minio()
    try:
        response = client.get_object(settings.MINIO_BUCKET, object_name)
        return response.read()
    except S3Error:
        return None


async def delete_file(object_name: str) -> bool:
    client = get_minio()
    try:
        client.remove_object(settings.MINIO_BUCKET, object_name)
        return True
    except S3Error:
        return False
