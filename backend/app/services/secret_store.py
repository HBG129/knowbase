"""Secret storage helpers for user-provided provider API keys."""
import ctypes
import os
from ctypes import wintypes

from app.config import settings
from app.core.security import decrypt_api_key, encrypt_api_key

CREDENTIAL_PREFIX = "cred:v1:"
CRED_TYPE_GENERIC = 1
CRED_PERSIST_LOCAL_MACHINE = 2


class CredentialError(RuntimeError):
    pass


class _CREDENTIALW(ctypes.Structure):
    _fields_ = [
        ("Flags", wintypes.DWORD),
        ("Type", wintypes.DWORD),
        ("TargetName", wintypes.LPWSTR),
        ("Comment", wintypes.LPWSTR),
        ("LastWritten", wintypes.FILETIME),
        ("CredentialBlobSize", wintypes.DWORD),
        ("CredentialBlob", ctypes.POINTER(ctypes.c_byte)),
        ("Persist", wintypes.DWORD),
        ("AttributeCount", wintypes.DWORD),
        ("Attributes", wintypes.LPVOID),
        ("TargetAlias", wintypes.LPWSTR),
        ("UserName", wintypes.LPWSTR),
    ]


PCREDENTIALW = ctypes.POINTER(_CREDENTIALW)


def _is_windows() -> bool:
    return os.name == "nt"


def _credential_target(user_id: str) -> str:
    return f"KnowBase:user:{user_id}:llm-api-key"


def _use_windows_credential_store() -> bool:
    return settings.API_KEY_STORAGE_BACKEND == "windows-credential" and _is_windows()


def write_secret(target: str, value: str) -> None:
    blob = value.encode("utf-16-le")
    blob_buffer = ctypes.create_string_buffer(blob)
    credential = _CREDENTIALW()
    credential.Type = CRED_TYPE_GENERIC
    credential.TargetName = target
    credential.CredentialBlobSize = len(blob)
    credential.CredentialBlob = ctypes.cast(blob_buffer, ctypes.POINTER(ctypes.c_byte))
    credential.Persist = CRED_PERSIST_LOCAL_MACHINE
    credential.UserName = "KnowBase"
    if not ctypes.windll.advapi32.CredWriteW(ctypes.byref(credential), 0):
        raise CredentialError(f"Windows Credential Manager write failed: {ctypes.get_last_error()}")


def read_secret(target: str) -> str:
    credential = PCREDENTIALW()
    if not ctypes.windll.advapi32.CredReadW(target, CRED_TYPE_GENERIC, 0, ctypes.byref(credential)):
        raise CredentialError("Saved API key was not found in Windows Credential Manager.")
    try:
        blob = ctypes.string_at(
            credential.contents.CredentialBlob,
            credential.contents.CredentialBlobSize,
        )
        return blob.decode("utf-16-le")
    finally:
        ctypes.windll.advapi32.CredFree(credential)


def delete_secret(target: str) -> None:
    ctypes.windll.advapi32.CredDeleteW(target, CRED_TYPE_GENERIC, 0)


def store_api_key(user_id: str, api_key: str) -> str:
    if _use_windows_credential_store():
        target = _credential_target(user_id)
        write_secret(target, api_key)
        return CREDENTIAL_PREFIX + target
    return encrypt_api_key(api_key)


def resolve_api_key(stored_api_key: str) -> str:
    if stored_api_key.startswith(CREDENTIAL_PREFIX):
        return read_secret(stored_api_key.removeprefix(CREDENTIAL_PREFIX))
    return decrypt_api_key(stored_api_key)


def delete_api_key(stored_api_key: str | None) -> None:
    if stored_api_key and stored_api_key.startswith(CREDENTIAL_PREFIX):
        delete_secret(stored_api_key.removeprefix(CREDENTIAL_PREFIX))
