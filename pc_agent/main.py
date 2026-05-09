from contextlib import asynccontextmanager

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


if __name__ == "__main__":
    import uvicorn

    config = load_config()
    uvicorn.run(
        "main:app",
        host=config.api.host,
        port=config.api.port,
        reload=False,
    )
