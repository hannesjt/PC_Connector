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
