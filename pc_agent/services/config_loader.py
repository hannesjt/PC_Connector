from pathlib import Path
import shutil
import subprocess
import sys

import yaml

from models.schemas import AppConfig

_config: AppConfig | None = None


def _base_dir() -> Path:
    """Return the directory next to the EXE (frozen) or the pc_agent source root."""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).parent
    return Path(__file__).parent.parent


def _example_path() -> Path:
    """Location of config.yaml.example – bundled inside the EXE or in the source tree."""
    if getattr(sys, "frozen", False):
        return Path(sys._MEIPASS) / "config.yaml.example"  # type: ignore[attr-defined]
    return Path(__file__).parent.parent / "config.yaml.example"


def _create_default_config(config_path: Path) -> None:
    """Copy config.yaml.example to config_path and open it for the user to edit."""
    example = _example_path()
    if example.exists():
        shutil.copy(example, config_path)
    else:
        # Fallback: write a minimal template
        config_path.write_text(
            "pc:\n"
            "  name: MY_PC\n"
            "  mac_address: \"AA-BB-CC-DD-EE-FF\"\n\n"
            "api:\n"
            "  host: \"0.0.0.0\"\n"
            "  port: 8420\n\n"
            "scripts: []\n"
            "category_order: []\n",
            encoding="utf-8",
        )

    msg = (
        f"Eine neue config.yaml wurde erstellt:\n{config_path}\n\n"
        "Bitte trage dort deine PC-Daten ein (Name und MAC-Adresse)\n"
        "und starte den PC Connector Agent danach erneut."
    )

    # Open the file in the default editor on Windows
    try:
        subprocess.Popen(["notepad.exe", str(config_path)])
    except Exception:
        pass

    # Show a message box on Windows, fall back to console
    try:
        import ctypes
        ctypes.windll.user32.MessageBoxW(0, msg, "PC Connector – Ersteinrichtung", 0x40)
    except Exception:
        print("\n" + "=" * 60)
        print(msg)
        print("=" * 60 + "\n")

    sys.exit(0)


def load_config(path: str = "config.yaml") -> AppConfig:
    global _config
    config_path = _base_dir() / path
    if not config_path.exists():
        _create_default_config(config_path)  # exits after showing instructions
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
    config_path = _base_dir() / path
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
