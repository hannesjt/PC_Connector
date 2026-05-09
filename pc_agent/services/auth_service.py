import json
import secrets
import time
from pathlib import Path

_pairing_code: str | None = None
_pairing_code_expires: float = 0
_paired_devices: dict[str, dict] = {}
_devices_file = Path(__file__).parent.parent / "paired_devices.json"
_loaded = False


def _ensure_loaded():
    global _paired_devices, _loaded
    if not _loaded:
        if _devices_file.exists():
            with open(_devices_file, encoding="utf-8") as f:
                _paired_devices = json.load(f)
        _loaded = True


def _save():
    with open(_devices_file, "w", encoding="utf-8") as f:
        json.dump(_paired_devices, f, indent=2)


def generate_pairing_code() -> str:
    global _pairing_code, _pairing_code_expires
    _pairing_code = f"{secrets.randbelow(1000000):06d}"
    _pairing_code_expires = time.time() + 300  # 5 minutes
    return _pairing_code


def get_pairing_code_info() -> dict | None:
    if _pairing_code is None or time.time() > _pairing_code_expires:
        return None
    return {
        "code": _pairing_code,
        "expires_in": int(_pairing_code_expires - time.time()),
    }


def verify_pairing_code(code: str, device_name: str) -> str | None:
    global _pairing_code
    if _pairing_code is None or time.time() > _pairing_code_expires:
        return None
    if not secrets.compare_digest(code.strip(), _pairing_code):
        return None
    token = secrets.token_urlsafe(32)
    _ensure_loaded()
    _paired_devices[token] = {
        "name": device_name,
        "paired_at": time.time(),
    }
    _pairing_code = None
    _save()
    return token


def is_valid_token(token: str) -> bool:
    _ensure_loaded()
    return token in _paired_devices


def get_paired_devices() -> list[dict]:
    _ensure_loaded()
    return [
        {
            "token_prefix": token[:8],
            "name": info.get("name", "Unbekannt"),
            "paired_at": info.get("paired_at", 0),
        }
        for token, info in _paired_devices.items()
    ]


def remove_device(token_prefix: str) -> bool:
    _ensure_loaded()
    to_remove = [k for k in _paired_devices if k.startswith(token_prefix)]
    if not to_remove:
        return False
    for k in to_remove:
        del _paired_devices[k]
    _save()
    return True
