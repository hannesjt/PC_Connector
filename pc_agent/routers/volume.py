"""Volume control endpoints – uses pycaw on Windows."""

from __future__ import annotations

import sys

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/api/volume", tags=["volume"])


class VolumeLevel(BaseModel):
    level: float  # 0.0 – 1.0


class MuteStatus(BaseModel):
    muted: bool


def _get_volume_interface():
    """Lazy-import and return the Windows audio volume interface."""
    if sys.platform != "win32":
        raise RuntimeError("Volume control is only supported on Windows")
    from pycaw.pycaw import AudioUtilities  # noqa: PLC0415

    speakers = AudioUtilities.GetSpeakers()
    return speakers.EndpointVolume


@router.get("/")
async def get_volume():
    vol = _get_volume_interface()
    level = vol.GetMasterVolumeLevelScalar()
    muted = bool(vol.GetMute())
    return {"level": round(level, 2), "muted": muted}


@router.post("/set")
async def set_volume(req: VolumeLevel):
    clamped = max(0.0, min(1.0, req.level))
    vol = _get_volume_interface()
    vol.SetMasterVolumeLevelScalar(clamped, None)
    return {"level": round(clamped, 2)}


@router.post("/mute")
async def toggle_mute(req: MuteStatus):
    vol = _get_volume_interface()
    vol.SetMute(int(req.muted), None)
    return {"muted": req.muted}
