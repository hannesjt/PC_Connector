from pathlib import Path

import yaml

from models.schemas import AppConfig

_config: AppConfig | None = None


def load_config(path: str = "config.yaml") -> AppConfig:
    global _config
    config_path = Path(__file__).parent.parent / path
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
    config_path = Path(__file__).parent.parent / path
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
