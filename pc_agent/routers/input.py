from __future__ import annotations

from fastapi import APIRouter

from models.schemas import (
    KeyboardKeyRequest,
    KeyboardTypeRequest,
    MouseClickRequest,
    MouseMoveRequest,
    MouseScrollRequest,
)

router = APIRouter(prefix="/api/input", tags=["input"])

_pyautogui = None


def _pag():
    """Lazy-load pyautogui so that importing this module does not require
    a graphical display (needed for headless CI / unit tests)."""
    global _pyautogui
    if _pyautogui is None:
        import pyautogui  # noqa: PLC0415
        pyautogui.FAILSAFE = False
        pyautogui.PAUSE = 0
        _pyautogui = pyautogui
    return _pyautogui


@router.post("/mouse/move")
async def mouse_move(req: MouseMoveRequest):
    _pag().moveRel(req.dx, req.dy, duration=0)
    return {"success": True}


@router.post("/mouse/click")
async def mouse_click(req: MouseClickRequest):
    pag = _pag()
    btn = req.button if req.button in ("left", "right", "middle") else "left"
    if req.double:
        pag.doubleClick(button=btn)
    else:
        pag.click(button=btn)
    return {"success": True}


@router.post("/mouse/scroll")
async def mouse_scroll(req: MouseScrollRequest):
    pag = _pag()
    if req.dy != 0:
        pag.scroll(int(req.dy))
    if req.dx != 0:
        pag.hscroll(int(req.dx))
    return {"success": True}


@router.post("/keyboard/type")
async def keyboard_type(req: KeyboardTypeRequest):
    if req.text:
        _pag().typewrite(req.text, interval=0.02)
    return {"success": True}


@router.post("/keyboard/key")
async def keyboard_key(req: KeyboardKeyRequest):
    _KEY_MAP = {
        "win": "winleft",
        "windows": "winleft",
        "super": "winleft",
        "back": "backspace",
        "del": "delete",
        "esc": "escape",
    }
    key = _KEY_MAP.get(req.key.lower(), req.key.lower())
    _pag().press(key)
    return {"success": True}
