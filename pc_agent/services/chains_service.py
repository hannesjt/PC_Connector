import json
import sys
from pathlib import Path

from models.schemas import ScriptChain


def _base_dir() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys.executable).parent
    return Path(__file__).parent.parent


def _chains_path() -> Path:
    return _base_dir() / "chains.json"


def _load_raw() -> list[dict]:
    if not _chains_path().exists():
        return []
    return json.loads(_chains_path().read_text(encoding="utf-8"))


def _save_raw(chains: list[dict]):
    _chains_path().write_text(json.dumps(chains, indent=2, ensure_ascii=False), encoding="utf-8")


def get_chains() -> list[ScriptChain]:
    return sorted([ScriptChain(**c) for c in _load_raw()], key=lambda c: c.order)


def reorder_chains(ordered_ids: list[str]):
    chains = _load_raw()
    order_map = {cid: i for i, cid in enumerate(ordered_ids)}
    for c in chains:
        if c["id"] in order_map:
            c["order"] = order_map[c["id"]]
    _save_raw(chains)


def save_chain(chain: ScriptChain):
    chains = _load_raw()
    idx = next((i for i, c in enumerate(chains) if c["id"] == chain.id), None)
    if idx is not None:
        chains[idx] = chain.model_dump()
    else:
        chains.append(chain.model_dump())
    _save_raw(chains)


def delete_chain(chain_id: str) -> bool:
    chains = _load_raw()
    new = [c for c in chains if c["id"] != chain_id]
    if len(new) == len(chains):
        return False
    _save_raw(new)
    return True


def get_chain(chain_id: str) -> ScriptChain | None:
    for c in _load_raw():
        if c["id"] == chain_id:
            return ScriptChain(**c)
    return None
