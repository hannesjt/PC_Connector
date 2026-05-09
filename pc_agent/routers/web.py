from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

from models.schemas import ScriptChain, ScriptConfig
from services import auth_service
from services.chains_service import delete_chain, get_chains, save_chain, reorder_chains
from services.config_loader import get_config, save_config

router = APIRouter(tags=["web"])


@router.get("/", response_class=HTMLResponse)
async def web_ui():
    html_path = Path(__file__).parent.parent / "templates" / "index.html"
    return HTMLResponse(html_path.read_text(encoding="utf-8"))


# --- Config ---


class UpdateNameRequest(BaseModel):
    name: str


@router.get("/web/config")
async def get_web_config():
    config = get_config()
    scripts = sorted(config.scripts, key=lambda s: s.order)
    return {
        "pc_name": config.pc.name,
        "mac_address": config.pc.mac_address,
        "port": config.api.port,
        "scripts": [s.model_dump() for s in scripts],
    }


@router.post("/web/config/name")
async def update_pc_name(req: UpdateNameRequest):
    config = get_config()
    config.pc.name = req.name
    save_config()
    return {"success": True}


# --- Scripts ---


@router.post("/web/config/scripts")
async def add_script(script: ScriptConfig):
    config = get_config()
    if any(s.id == script.id for s in config.scripts):
        raise HTTPException(400, "Script-ID existiert bereits")
    script.order = max((s.order for s in config.scripts), default=-1) + 1
    config.scripts.append(script)
    save_config()
    return {"success": True}


@router.put("/web/config/scripts/{script_id}")
async def update_script(script_id: str, script: ScriptConfig):
    config = get_config()
    idx = next(
        (i for i, s in enumerate(config.scripts) if s.id == script_id), None
    )
    if idx is None:
        raise HTTPException(404, "Script nicht gefunden")
    script.order = config.scripts[idx].order
    config.scripts[idx] = script
    save_config()
    return {"success": True}


@router.delete("/web/config/scripts/{script_id}")
async def delete_script(script_id: str):
    config = get_config()
    config.scripts = [s for s in config.scripts if s.id != script_id]
    save_config()
    return {"success": True}


class ReorderRequest(BaseModel):
    ordered_ids: list[str]


@router.post("/web/config/scripts/reorder")
async def reorder_scripts(req: ReorderRequest):
    config = get_config()
    order_map = {sid: i for i, sid in enumerate(req.ordered_ids)}
    for s in config.scripts:
        if s.id in order_map:
            s.order = order_map[s.id]
    save_config()
    return {"success": True}


# --- Groups ---


class AssignGroupRequest(BaseModel):
    group: str
    script_ids: list[str]
    old_group: str | None = None


@router.get("/web/groups")
async def list_groups_web():
    config = get_config()
    groups: dict[str, list[str]] = {}
    for s in config.scripts:
        if s.group:
            groups.setdefault(s.group, []).append(s.id)
    order = config.category_order
    known = [g for g in order if g in groups]
    rest = [g for g in groups if g not in order]
    ordered = known + rest
    return [{"name": g, "script_ids": groups[g]} for g in ordered]


@router.post("/web/categories/reorder")
async def reorder_categories_web(req: ReorderRequest):
    config = get_config()
    config.category_order = req.ordered_ids
    save_config()
    return {"success": True}


@router.post("/web/config/groups/assign")
async def assign_group_web(req: AssignGroupRequest):
    config = get_config()
    if req.old_group and req.old_group != req.group:
        for s in config.scripts:
            if s.group == req.old_group:
                s.group = ""
    for s in config.scripts:
        if s.group == req.group and s.id not in req.script_ids:
            s.group = ""
        elif s.id in req.script_ids:
            s.group = req.group
    save_config()
    return {"success": True}


# --- Chains ---


@router.get("/web/chains")
async def list_chains():
    return [c.model_dump() for c in get_chains()]


@router.post("/web/chains")
async def create_chain(chain: ScriptChain):
    save_chain(chain)
    return {"success": True}


@router.put("/web/chains/{chain_id}")
async def update_chain(chain_id: str, chain: ScriptChain):
    chain.id = chain_id
    save_chain(chain)
    return {"success": True}


@router.delete("/web/chains/{chain_id}")
async def remove_chain(chain_id: str):
    if not delete_chain(chain_id):
        raise HTTPException(404, "Ablauf nicht gefunden")
    return {"success": True}


@router.post("/web/chains/reorder")
async def reorder_chains_web(req: ReorderRequest):
    reorder_chains(req.ordered_ids)
    return {"success": True}


# --- Pairing ---


@router.post("/web/pairing/generate")
async def generate_code():
    code = auth_service.generate_pairing_code()
    return {"code": code, "expires_in": 300}


@router.get("/web/pairing/code")
async def get_current_code():
    info = auth_service.get_pairing_code_info()
    if info is None:
        return {"active": False}
    return {"active": True, **info}


@router.get("/web/pairing/devices")
async def list_paired_devices():
    return auth_service.get_paired_devices()


@router.delete("/web/pairing/devices/{token_prefix}")
async def remove_paired_device(token_prefix: str):
    if auth_service.remove_device(token_prefix):
        return {"success": True}
    raise HTTPException(404, "Gerät nicht gefunden")

