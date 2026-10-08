"""
Image storage abstraction.

Routers depend on `ImageStorageService`, never on a concrete backend. This
keeps the local dev flow (save to disk, serve via FastAPI StaticFiles)
swappable for a real object-storage backend later without touching any
router code. No credentials are hard-coded anywhere here — everything comes
from environment variables via `app.config.Settings`.
"""
import abc
import os
import uuid

from fastapi import HTTPException, UploadFile, status

from app.config import get_settings

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB


class ImageStorageBackend(abc.ABC):
    @abc.abstractmethod
    def save(self, file: UploadFile, contents: bytes) -> str:
        """Persist the file and return a publicly-accessible URL/path."""
        raise NotImplementedError


class LocalImageStorage(ImageStorageBackend):
    """Development-friendly local disk storage, served via /static/uploads."""

    def __init__(self, upload_dir: str, url_prefix: str):
        self.upload_dir = upload_dir
        self.url_prefix = url_prefix
        os.makedirs(self.upload_dir, exist_ok=True)

    def save(self, file: UploadFile, contents: bytes) -> str:
        ext = os.path.splitext(file.filename or "")[1].lower() or ".jpg"
        filename = f"{uuid.uuid4().hex}{ext}"
        path = os.path.join(self.upload_dir, filename)
        with open(path, "wb") as f:
            f.write(contents)
        return f"{self.url_prefix}/{filename}"


class S3ImageStorage(ImageStorageBackend):
    """
    Production object-storage backend. Requires boto3 and the S3_* env vars
    in .env.example to be set. Not wired up by default so the project runs
    out of the box without any cloud credentials.
    """

    def __init__(self, bucket: str, region: str, access_key: str, secret_key: str, public_url_base: str):
        try:
            import boto3  # imported lazily so boto3 isn't a hard dependency for local dev
        except ImportError as exc:  # pragma: no cover
            raise RuntimeError("boto3 is required for S3 image storage; add it to requirements.txt") from exc

        self.bucket = bucket
        self.public_url_base = public_url_base.rstrip("/")
        self.client = boto3.client(
            "s3",
            region_name=region,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
        )

    def save(self, file: UploadFile, contents: bytes) -> str:
        ext = os.path.splitext(file.filename or "")[1].lower() or ".jpg"
        key = f"listings/{uuid.uuid4().hex}{ext}"
        self.client.put_object(Bucket=self.bucket, Key=key, Body=contents, ContentType=file.content_type)
        return f"{self.public_url_base}/{key}"


def get_image_storage() -> ImageStorageBackend:
    settings = get_settings()
    if settings.image_storage_backend == "s3":
        missing = [
            name for name, val in [
                ("S3_BUCKET_NAME", settings.s3_bucket_name),
                ("S3_REGION", settings.s3_region),
                ("S3_ACCESS_KEY_ID", settings.s3_access_key_id),
                ("S3_SECRET_ACCESS_KEY", settings.s3_secret_access_key),
                ("S3_PUBLIC_URL_BASE", settings.s3_public_url_base),
            ] if not val
        ]
        if missing:
            raise RuntimeError(f"Missing required S3 settings: {', '.join(missing)}")
        return S3ImageStorage(
            bucket=settings.s3_bucket_name,
            region=settings.s3_region,
            access_key=settings.s3_access_key_id,
            secret_key=settings.s3_secret_access_key,
            public_url_base=settings.s3_public_url_base,
        )
    return LocalImageStorage(settings.local_upload_dir, settings.local_upload_url_prefix)


async def validate_and_read_image(file: UploadFile) -> bytes:
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported image type: {file.content_type}. Allowed: {sorted(ALLOWED_CONTENT_TYPES)}",
        )
    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image exceeds the 5 MB size limit",
        )
    return contents
