import asyncio
import json
import logging

from services.config_loader import get_config

logger = logging.getLogger(__name__)

DISCOVERY_PORT = 8421
DISCOVERY_MAGIC = b"PCCONNECTOR_DISCOVER"


class DiscoveryProtocol(asyncio.DatagramProtocol):
    def __init__(self):
        self.transport = None

    def connection_made(self, transport):
        self.transport = transport

    def datagram_received(self, data, addr):
        if data.strip() == DISCOVERY_MAGIC:
            config = get_config()
            response = json.dumps({
                "name": config.pc.name,
                "port": config.api.port,
                "mac": config.pc.mac_address,
            }).encode()
            self.transport.sendto(response, addr)
            logger.info(f"Discovery response sent to {addr}")


async def start_discovery_listener():
    config = get_config()
    loop = asyncio.get_running_loop()
    transport, _ = await loop.create_datagram_endpoint(
        DiscoveryProtocol,
        local_addr=("0.0.0.0", DISCOVERY_PORT),
    )
    logger.info(f"Discovery listener started on UDP port {DISCOVERY_PORT}")
    return transport
