"""
Central path resolution for PC Connector Agent.

Data files (config.yaml, paired_devices.json, chains.json) are stored in:
  - Frozen (EXE):  %%APPDATA%%/PC Connector/
  - Source / dev:  <repo>/pc_agent/
"""

import os
import sys
from pathlib import Path


def data_dir() -> Path:
    """Returns the directory where all runtime data files are stored."""
    if getattr(sys, "frozen", False):
        appdata = os.environ.get("APPDATA") or Path.home() / "AppData" / "Roaming"
        d = Path(appdata) / "PC Connector"
        d.mkdir(parents=True, exist_ok=True)
        return d
    return Path(__file__).parent.parent
