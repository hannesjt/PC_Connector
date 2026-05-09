from fastapi import APIRouter

from models.schemas import StatusResponse
from services.config_loader import get_config

router = APIRouter(prefix="/api", tags=["status"])


@router.get("/status", response_model=StatusResponse)
async def get_status():
    config = get_config()
    return StatusResponse(
        status="online",
        pc_name=config.pc.name,
        mac_address=config.pc.mac_address,
    )
