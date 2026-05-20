import pyautogui
from fastapi import APIRouter

from models.schemas import (
    KeyboardKeyRequest,
    KeyboardTypeRequest,
    MouseClickRequest,
    MouseMoveRequest,
    MouseScrollRequest,
)

# Prevent pyautogui from raising FailSafeException when the cursor hits a corner
pyautogui.FAILSAFE = False
# Disable the default pause between pyautogui calls for lower latency
pyautogui.PAUSE = 0

router = APIRouter(prefix="/api/input", tags=["input"])


@router.post("/mouse/move")
async def mouse_move(req: MouseMoveRequest):
    pyautogui.moveRel(req.dx, req.dy, duration=0)
    return {"success": True}


@router.post("/mouse/click")
async def mouse_click(req: MouseClickRequest):
    btn = req.button if req.button in ("left", "right", "middle") else "left"
    if req.double:
        pyautogui.doubleClick(button=btn)
    else:
        pyautogui.click(button=btn)
    return {"success": True}


@router.post("/mouse/scroll")
async def mouse_scroll(req: MouseScrollRequest):
    if req.dy != 0:
        pyautogui.scroll(int(req.dy))
    if req.dx != 0:
        pyautogui.hscroll(int(req.dx))
    return {"success": True}


@router.post("/keyboard/type")
async def keyboard_type(req: KeyboardTypeRequest):
    if req.text:
        pyautogui.typewrite(req.text, interval=0.02)
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
    pyautogui.press(key)
    return {"success": True}
