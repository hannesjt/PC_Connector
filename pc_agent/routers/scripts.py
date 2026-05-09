import asyncio

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from models.schemas import ScriptChain, ScriptListItem, ScriptRunResponse
from services.chains_service import get_chain, get_chains, reorder_chains
from services.config_loader import get_config, save_config
from services.script_runner import run_script

router = APIRouter(prefix="/api", tags=["scripts"])


@router.get("/scripts", response_model=list[ScriptListItem])
async def list_scripts():
    config = get_config()
    scripts = sorted(config.scripts, key=lambda s: s.order)
    return [
        ScriptListItem(
            id=s.id,
            name=s.name,
            icon=s.icon,
            confirm=s.confirm,
            group=s.group,
            order=s.order,
        )
        for s in scripts
    ]


@router.get("/groups")
async def list_groups():
    config = get_config()
    groups: dict[str, list[str]] = {}
    for s in config.scripts:
        if s.group:
            groups.setdefault(s.group, []).append(s.id)
    return [{"name": g, "script_ids": ids} for g, ids in groups.items()]


class AssignGroupRequest(BaseModel):
    group: str
    script_ids: list[str]
    old_group: str | None = None


@router.post("/scripts/assign-group")
async def assign_group(req: AssignGroupRequest):
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


@router.post("/scripts/{script_id}/run", response_model=ScriptRunResponse)
async def run_script_endpoint(script_id: str):
    config = get_config()
    script = next((s for s in config.scripts if s.id == script_id), None)
    if script is None:
        raise HTTPException(status_code=404, detail=f"Script '{script_id}' not found")
    return await run_script(script)


class ReorderRequest(BaseModel):
    ordered_ids: list[str]


@router.post("/scripts/reorder")
async def reorder_scripts(req: ReorderRequest):
    config = get_config()
    order_map = {sid: i for i, sid in enumerate(req.ordered_ids)}
    for s in config.scripts:
        if s.id in order_map:
            s.order = order_map[s.id]
    save_config()
    return {"success": True}


@router.get("/chains", response_model=list[ScriptChain])
async def list_chains():
    return get_chains()


@router.post("/chains/reorder")
async def reorder_chains_endpoint(req: ReorderRequest):
    reorder_chains(req.ordered_ids)
    return {"success": True}


@router.get("/categories")
async def list_categories():
    config = get_config()
    order = config.category_order
    groups: dict[str, list[str]] = {}
    for s in config.scripts:
        if s.group:
            groups.setdefault(s.group, []).append(s.id)
    known = [g for g in order if g in groups]
    rest = [g for g in groups if g not in order]
    return {"ordered": known + rest}


@router.post("/categories/reorder")
async def reorder_categories(req: ReorderRequest):
    config = get_config()
    config.category_order = req.ordered_ids
    save_config()
    return {"success": True}


@router.post("/chains/{chain_id}/run")
async def run_chain_endpoint(chain_id: str):
    chain = get_chain(chain_id)
    if chain is None:
        raise HTTPException(status_code=404, detail=f"Chain '{chain_id}' not found")
    config = get_config()
    results = []
    for i, step in enumerate(chain.steps):
        if i > 0 and step.delay_seconds > 0:
            await asyncio.sleep(step.delay_seconds)
        script = next((s for s in config.scripts if s.id == step.script_id), None)
        if script is None:
            results.append({"script_id": step.script_id, "error": "Script nicht gefunden"})
            continue
        result = await run_script(script)
        results.append(result.model_dump())
    return {"chain_id": chain_id, "results": results}
