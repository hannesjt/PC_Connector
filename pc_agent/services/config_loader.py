from pathlib import Path
import socket
import sys
import uuid

import yaml

from models.schemas import AppConfig
from services.paths import data_dir

_config: AppConfig | None = None


def _detect_pc_name() -> str:
    try:
        return socket.gethostname()
    except Exception:
        return "MY_PC"


def _detect_mac() -> str:
    """Return the MAC of the fastest active ethernet adapter, or uuid fallback."""
    try:
        result = __import__("subprocess").run(
            ["powershell", "-NoProfile", "-Command",
             "(Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and "
             "$_.InterfaceType -eq 6 } | Sort-Object Speed -Descending | "
             "Select-Object -First 1).MacAddress"],
            capture_output=True, text=True, timeout=5,
        )
        mac = result.stdout.strip()
        if mac and len(mac) >= 17:
            return mac
    except Exception:
        pass
    raw = f"{uuid.getnode():012X}"
    return "-".join(raw[i:i+2] for i in range(0, 12, 2))


def _create_default_config(config_path: Path) -> None:
    """Auto-detect PC name and MAC address and write config.yaml."""
    pc_name = _detect_pc_name()
    mac = _detect_mac()
    config_path.write_text(
        f"pc:\n"
        f"  name: {pc_name}\n"
        f"  mac_address: \"{mac}\"\n\n"
        f"api:\n"
        f"  host: \"0.0.0.0\"\n"
        f"  port: 8420\n\n"
        f"scripts: []\n"
        f"category_order: []\n",
        encoding="utf-8",
    )


def load_config(path: str = "config.yaml") -> AppConfig:
    global _config
    p = Path(path)
    config_path = p if p.is_absolute() else data_dir() / path
    if not config_path.exists():
        _create_default_config(config_path)
    with open(config_path, encoding="utf-8") as f:
        raw = yaml.safe_load(f)
    _config = AppConfig(**raw)
    return _config


def get_config() -> AppConfig:
    if _config is None:
        return load_config()
    return _config


def save_config(path: str = "config.yaml"):
    if _config is None:
        return
    config_path = data_dir() / path
    data = _config.model_dump()
    with open(config_path, "w", encoding="utf-8") as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)


def get_ordered_groups(config: AppConfig) -> list[tuple[str, list[str]]]:
    """Returns (group_name, script_ids) pairs in category_order, unknown groups appended."""
    groups: dict[str, list[str]] = {}
    for s in config.scripts:
        if s.group:
            groups.setdefault(s.group, []).append(s.id)
    known = [g for g in config.category_order if g in groups]
    rest = [g for g in groups if g not in config.category_order]
    return [(g, groups[g]) for g in known + rest]
