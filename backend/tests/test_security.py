from passlib.context import CryptContext

from app.core.security import hash_password, verify_password


def test_long_passwords_are_not_silently_truncated():
    password = "a" * 72 + "-first"
    different_suffix = "a" * 72 + "-second"

    hashed = hash_password(password)

    assert verify_password(password, hashed)
    assert not verify_password(different_suffix, hashed)


def test_legacy_bcrypt_passwords_remain_valid():
    legacy_context = CryptContext(schemes=["bcrypt"])
    legacy_hash = legacy_context.hash("legacy-password")

    assert verify_password("legacy-password", legacy_hash)
