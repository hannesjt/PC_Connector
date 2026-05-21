"""Clipboard endpoint – send text from mobile to PC clipboard."""

from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel


router = APIRouter(prefix="/api/clipboard", tags=["clipboard"])


class ClipboardSetRequest(BaseModel):
    text: str


@router.get("/")
async def get_clipboard():
    import pyperclip  # noqa: PLC0415
    try:
        text = pyperclip.paste()
    except Exception:
        text = ""
    return {"text": text}


@router.post("/set")
async def set_clipboard(req: ClipboardSetRequest):
    import pyperclip  # noqa: PLC0415
    pyperclip.copy(req.text)
    return {"success": True}
