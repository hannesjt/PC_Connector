"""Script history endpoint – logs all script executions."""

from __future__ import annotations

import json
import time
from pathlib import Path

from fastapi import APIRouter
from pydantic import BaseModel

from services.paths import data_dir

router = APIRouter(prefix="/api/history", tags=["history"])

_HISTORY_FILE = "script_history.json"
_MAX_ENTRIES = 200


class HistoryEntry(BaseModel):
    script_id: str
    script_name: str
    success: bool
    exit_code: int
    timestamp: float
    stderr: str = ""


def _history_path() -> Path:
    return data_dir() / _HISTORY_FILE


def _load_history() -> list[dict]:
    path = _history_path()
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return []


def _save_history(entries: list[dict]):
    path = _history_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(entries[-_MAX_ENTRIES:], ensure_ascii=False), encoding="utf-8")


def add_history_entry(script_id: str, script_name: str, success: bool, exit_code: int, stderr: str = ""):
    """Called from the script runner after each execution."""
    entries = _load_history()
    entries.append({
        "script_id": script_id,
        "script_name": script_name,
        "success": success,
        "exit_code": exit_code,
        "timestamp": time.time(),
        "stderr": stderr[:500],  # limit size
    })
    _save_history(entries)


@router.get("/", response_model=list[HistoryEntry])
async def get_history(limit: int = 50):
    """Return the most recent script executions."""
    entries = _load_history()
    return entries[-limit:][::-1]  # newest first


@router.delete("/")
async def clear_history():
    """Clear all history entries."""
    _save_history([])
    return {"success": True}
