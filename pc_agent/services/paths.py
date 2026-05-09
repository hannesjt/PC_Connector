"""
Central path resolution for PC Connector Agent.

Data files (config.yaml, paired_devices.json, chains.json) are stored in:
  - Frozen (EXE):  %%APPDATA%%\\PC Connector\\
  - Source / dev:  <repo>/pc_agent/   (unchanged behaviour)
"""

import os
import sys
from pathlib import Path


def data_dir() -> Path:
    """Returns the directory where all runtime data files are stored."""
    if getattr(sys, "frozen", False):
        # Windows: C:\Users\<user>\AppData\Roaming\PC Connector
        appdata = os.environ.get("APPDATA") or Path.home() / "AppData" / "Roaming"
        d = Path(appdata) / "PC Connector"
        d.mkdir(parents=True, exist_ok=True)
        return d
    # Running from source – keep files next to pc_agent/
    return Path(__file__).parent.parent


def bundled_example() -> Path:
    """config.yaml.example bundled inside the EXE, or the source tree copy."""
    if getattr(sys, "frozen", False):
        return Path(sys._MEIPASS) / "config.yaml.example"  # type: ignore[attr-defined]
    return Path(__file__).parent.parent / "config.yaml.example"
