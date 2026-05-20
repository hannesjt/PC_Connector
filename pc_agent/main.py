import os
import sys
import threading
import webbrowser
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import Depends, FastAPI, HTTPException, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from routers import pairing, scripts, status, web
from routers import input as input_router
from services.auth_service import is_valid_token
from services.config_loader import load_config
from services.discovery_service import start_discovery_listener


# ---------------------------------------------------------------------------
# Single-instance guard
# ---------------------------------------------------------------------------

def _ensure_single_instance() -> object:
    """
    Prevent the agent from being started more than once.

    On Windows: creates a named mutex.  A second instance detects the
    existing mutex and exits with a user-friendly message.

    On other platforms: falls back to a lock file in the temp directory.

    Returns the lock handle so the caller can keep it alive for the
    duration of the process.
    """
    if sys.platform == "win32":
        import ctypes
        _MUTEX_NAME = "Global\\PCConnectorAgent_SingleInstance"
        handle = ctypes.windll.kernel32.CreateMutexW(None, True, _MUTEX_NAME)
        last_err = ctypes.windll.kernel32.GetLastError()
        ERROR_ALREADY_EXISTS = 183
        if last_err == ERROR_ALREADY_EXISTS:
            try:
                import ctypes.wintypes
                MB_OK = 0x00
                MB_ICONWARNING = 0x30
                HWND_DESKTOP = 0
                ctypes.windll.user32.MessageBoxW(
                    HWND_DESKTOP,
                    "PC Connector Agent läuft bereits im Hintergrund.\n"
                    "Schaue in der Taskleiste nach dem Symbol.",
                    "PC Connector Agent",
                    MB_OK | MB_ICONWARNING,
                )
            except Exception:
                pass
            sys.exit(0)
        return handle  # keep alive
    else:
        import fcntl
        import tempfile
        lock_path = Path(tempfile.gettempdir()) / "pc_connector_agent.lock"
        lock_file = open(lock_path, "w")
        try:
            fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            print(
                "PC Connector Agent läuft bereits. Beende.",
                file=sys.stderr,
            )
            sys.exit(0)
        return lock_file  # keep alive


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
app.include_router(input_router.router, dependencies=[Depends(verify_token)])

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

    # Block a second instance before doing anything else.
    _lock = _ensure_single_instance()

    # In a frozen EXE there is no console, so sys.stdout/stderr are None.
    # uvicorn's logging formatter calls .isatty() on them → AttributeError.
    if sys.stdout is None:
        sys.stdout = open(os.devnull, "w")  # type: ignore[assignment]
    if sys.stderr is None:
        sys.stderr = open(os.devnull, "w")  # type: ignore[assignment]

    config = load_config()
    host = config.api.host if config.api.host != "0.0.0.0" else "localhost"
    url = f"http://{host}:{config.api.port}"

    server = uvicorn.Server(
        uvicorn.Config(app, host=config.api.host, port=config.api.port, reload=False)
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
