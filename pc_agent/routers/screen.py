"""Screenshot endpoint – capture the PC screen and return as JPEG."""

from __future__ import annotations

import io
from fastapi import APIRouter
from fastapi.responses import StreamingResponse

router = APIRouter(prefix="/api/screen", tags=["screen"])


@router.get("/screenshot")
async def screenshot(quality: int = 50, scale: float = 0.5):
    """Capture a screenshot, scale it down and return as JPEG.

    Args:
        quality: JPEG quality 1-95 (lower = smaller file)
        scale: Scale factor 0.1-1.0 (lower = smaller resolution)
    """
    from PIL import ImageGrab  # noqa: PLC0415

    img = ImageGrab.grab()
    if scale < 1.0:
        new_size = (int(img.width * scale), int(img.height * scale))
        img = img.resize(new_size)

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=max(1, min(95, quality)))
    buf.seek(0)

    return StreamingResponse(buf, media_type="image/jpeg")
