from fastapi import APIRouter

from models.schemas import PairingRequest, PairingResponse
from services import auth_service
from services.config_loader import get_config

router = APIRouter(prefix="/api", tags=["pairing"])


@router.post("/pair", response_model=PairingResponse)
async def pair_device(request: PairingRequest):
    token = auth_service.verify_pairing_code(request.code, request.device_name)
    if token is None:
        return PairingResponse(
            success=False,
            message="Ungültiger oder abgelaufener Code.",
        )
    config = get_config()
    return PairingResponse(
        success=True,
        token=token,
        message="Gerät erfolgreich verbunden!",
        mac_address=config.pc.mac_address,
        pc_name=config.pc.name,
    )
