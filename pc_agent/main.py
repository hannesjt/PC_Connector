import sys
import threading
import webbrowser
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import Depends, FastAPI, HTTPException, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from routers import pairing, scripts, status, web
from services.auth_service import is_valid_token
from services.config_loader import load_config
from services.discovery_service import start_discovery_listener


@asynccontextmanager
async def lifespan(app: FastAPI):
    transport = await start_discovery_listener()
    yield
    transport.close()


app = FastAPI(title="PC Connector Agent", version="1.0.0", lifespan=lifespan)

security = HTTPBearer(auto_error=False)


def verify_token(
    credentials: HTTPAuthorizationCredentials | None = Security(security),
):
    if credentials is None or not is_valid_token(credentials.credentials):
        raise HTTPException(
            status_code=401,
            detail="Nicht authentifiziert. Bitte Gerät zuerst koppeln.",
        )


# Protected routes (mobile app)
app.include_router(status.router, dependencies=[Depends(verify_token)])
app.include_router(scripts.router, dependencies=[Depends(verify_token)])

# Unprotected routes (pairing + web UI)
app.include_router(pairing.router)
app.include_router(web.router)


def _get_icon_path() -> Path:
    """Returns the path to icon.png, works both frozen (PyInstaller) and from source."""
    if getattr(sys, "frozen", False):
        return Path(sys._MEIPASS) / "icon.png"
    return Path(__file__).parent.parent / "assets" / "icon" / "icon.png"


if __name__ == "__main__":
    import pystray
    import uvicorn
    from PIL import Image

    config = load_config()
    host = config.api.host if config.api.host != "0.0.0.0" else "localhost"
    url = f"http://{host}:{config.api.port}"

    server = uvicorn.Server(
        uvicorn.Config("main:app", host=config.api.host, port=config.api.port, reload=False)
    )

    server_thread = threading.Thread(target=server.run, daemon=True)
    server_thread.start()

    def open_website(icon, item):
        webbrowser.open(url)

    def exit_app(icon, item):
        server.should_exit = True
        icon.stop()

    image = Image.open(_get_icon_path())
    menu = pystray.Menu(
        pystray.MenuItem("Website öffnen", open_website),
        pystray.MenuItem("Beenden", exit_app),
    )
    tray = pystray.Icon("PC Connector", image, "PC Connector Agent", menu)
    tray.run()
