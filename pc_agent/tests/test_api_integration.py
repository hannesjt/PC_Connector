"""Integration tests for the FastAPI endpoints via TestClient."""

import json
from pathlib import Path
from unittest.mock import patch, MagicMock

import yaml
import pytest
from fastapi.testclient import TestClient

from services import auth_service, config_loader, chains_service
from models.schemas import ScriptConfig, ScriptChain, ChainStep


@pytest.fixture(autouse=True)
def _setup_env(tmp_path):
    """Set up a clean config and chains file for each test."""
    # Config
    config_path = tmp_path / "config.yaml"
    data = {
        "pc": {"name": "TestPC", "mac_address": "AA-BB-CC-DD-EE-FF"},
        "api": {"host": "0.0.0.0", "port": 8420},
        "scripts": [
            {"id": "s1", "name": "Script 1", "command": "echo 1", "order": 0},
            {"id": "s2", "name": "Script 2", "command": "echo 2", "group": "System", "order": 1},
        ],
        "category_order": ["System"],
    }
    config_path.write_text(yaml.dump(data), encoding="utf-8")
    config_loader._config = None
    # Chains
    chains_path = tmp_path / "chains.json"
    chains_data = [
        {"id": "ch1", "name": "Chain 1", "steps": [{"script_id": "s1", "delay_seconds": 0}], "order": 0},
    ]
    chains_path.write_text(json.dumps(chains_data), encoding="utf-8")

    # Auth
    auth_service._pairing_code = None
    auth_service._pairing_code_expires = 0
    auth_service._paired_devices = {"test_token_1234567890": {"name": "TestPhone", "paired_at": 0}}
    auth_service._loaded = True

    with patch.object(chains_service, "data_dir", return_value=tmp_path), \
         patch.object(auth_service, "_save"):
        config_loader.load_config(str(config_path))
        # Import app after patching
        from main import app
        yield app, config_path


@pytest.fixture
def client(_setup_env):
    app, _ = _setup_env
    return TestClient(app)


@pytest.fixture
def auth_headers():
    return {"Authorization": "Bearer test_token_1234567890"}


# ── Status ─────────────────────────────────────────────

class TestStatusEndpoint:
    def test_status_authorized(self, client, auth_headers):
        r = client.get("/api/status", headers=auth_headers)
        assert r.status_code == 200
        data = r.json()
        assert data["status"] == "online"
        assert data["pc_name"] == "TestPC"

    def test_status_unauthorized(self, client):
        r = client.get("/api/status")
        assert r.status_code == 401


# ── Scripts ────────────────────────────────────────────

class TestScriptsEndpoint:
    def test_list_scripts(self, client, auth_headers):
        r = client.get("/api/scripts", headers=auth_headers)
        assert r.status_code == 200
        scripts = r.json()
        assert len(scripts) == 2
        # Should be sorted by order
        assert scripts[0]["id"] == "s1"
        assert scripts[1]["id"] == "s2"
        # is_global field should be present
        assert "is_global" in scripts[0]
        assert scripts[0]["is_global"] is False

    def test_list_scripts_unauthorized(self, client):
        r = client.get("/api/scripts")
        assert r.status_code == 401

    def test_reorder_scripts(self, client, auth_headers):
        r = client.post(
            "/api/scripts/reorder",
            headers=auth_headers,
            json={"ordered_ids": ["s2", "s1"]},
        )
        assert r.status_code == 200
        # Verify new order
        r2 = client.get("/api/scripts", headers=auth_headers)
        scripts = r2.json()
        assert scripts[0]["id"] == "s2"
        assert scripts[1]["id"] == "s1"

    def test_run_script(self, client, auth_headers):
        r = client.post("/api/scripts/s1/run", headers=auth_headers)
        assert r.status_code == 200
        data = r.json()
        assert data["script_id"] == "s1"
        assert data["success"] is True

    def test_run_nonexistent_script(self, client, auth_headers):
        r = client.post("/api/scripts/nonexistent/run", headers=auth_headers)
        assert r.status_code == 404


# ── Groups ─────────────────────────────────────────────

class TestGroupsEndpoint:
    def test_assign_group(self, client, auth_headers):
        r = client.post(
            "/api/scripts/assign-group",
            headers=auth_headers,
            json={"group": "Games", "script_ids": ["s1"]},
        )
        assert r.status_code == 200
        # Verify
        r2 = client.get("/api/scripts", headers=auth_headers)
        s1 = next(s for s in r2.json() if s["id"] == "s1")
        assert s1["group"] == "Games"

    def test_rename_group(self, client, auth_headers):
        r = client.post(
            "/api/scripts/assign-group",
            headers=auth_headers,
            json={"group": "Werkzeuge", "script_ids": ["s2"], "old_group": "System"},
        )
        assert r.status_code == 200


# ── Categories ─────────────────────────────────────────

class TestCategoriesEndpoint:
    def test_list_categories(self, client, auth_headers):
        r = client.get("/api/categories", headers=auth_headers)
        assert r.status_code == 200
        data = r.json()
        assert "System" in data["ordered"]

    def test_reorder_categories(self, client, auth_headers):
        r = client.post(
            "/api/categories/reorder",
            headers=auth_headers,
            json={"ordered_ids": ["System"]},
        )
        assert r.status_code == 200


# ── Chains ─────────────────────────────────────────────

class TestChainsEndpoint:
    def test_list_chains(self, client, auth_headers):
        r = client.get("/api/chains", headers=auth_headers)
        assert r.status_code == 200
        chains = r.json()
        assert len(chains) == 1
        assert chains[0]["id"] == "ch1"

    def test_reorder_chains(self, client, auth_headers):
        r = client.post(
            "/api/chains/reorder",
            headers=auth_headers,
            json={"ordered_ids": ["ch1"]},
        )
        assert r.status_code == 200


# ── Pairing ────────────────────────────────────────────

class TestPairingEndpoint:
    def test_pair_with_valid_code(self, client):
        code = auth_service.generate_pairing_code()
        r = client.post("/api/pair", json={"code": code, "device_name": "Pixel 10"})
        assert r.status_code == 200
        data = r.json()
        assert data["success"] is True
        assert data["token"] is not None
        assert data["pc_name"] == "TestPC"

    def test_pair_with_invalid_code(self, client):
        auth_service.generate_pairing_code()
        r = client.post("/api/pair", json={"code": "000000", "device_name": "Phone"})
        data = r.json()
        assert data["success"] is False
        assert data["token"] is None


# ── Web UI ─────────────────────────────────────────────

class TestWebEndpoints:
    def test_web_ui_html(self, client):
        r = client.get("/")
        assert r.status_code == 200
        assert "PC Connector" in r.text

    def test_web_config(self, client):
        r = client.get("/web/config")
        assert r.status_code == 200
        data = r.json()
        assert data["pc_name"] == "TestPC"
        assert len(data["scripts"]) == 2

    def test_web_groups(self, client):
        r = client.get("/web/groups")
        assert r.status_code == 200
        groups = r.json()
        assert any(g["name"] == "System" for g in groups)

    def test_web_add_script(self, client):
        r = client.post("/web/config/scripts", json={
            "id": "new", "name": "New Script", "command": "echo new",
        })
        assert r.status_code == 200

    def test_web_add_global_script(self, client):
        r = client.post("/web/config/scripts", json={
            "id": "global_s", "name": "Global Script", "command": "echo global",
            "is_global": True,
        })
        assert r.status_code == 200
        # Verify it is stored as global
        cfg = client.get("/web/config").json()
        gs = next(s for s in cfg["scripts"] if s["id"] == "global_s")
        assert gs["is_global"] is True

    def test_web_add_duplicate_script(self, client):
        r = client.post("/web/config/scripts", json={
            "id": "s1", "name": "Dup", "command": "echo",
        })
        assert r.status_code == 400

    def test_web_update_script(self, client):
        r = client.put("/web/config/scripts/s1", json={
            "id": "s1", "name": "Updated", "command": "echo updated",
        })
        assert r.status_code == 200

    def test_web_delete_script(self, client):
        r = client.delete("/web/config/scripts/s1")
        assert r.status_code == 200

    def test_web_pairing_generate(self, client):
        r = client.post("/web/pairing/generate")
        assert r.status_code == 200
        data = r.json()
        assert len(data["code"]) == 6

    def test_web_pairing_devices(self, client):
        r = client.get("/web/pairing/devices")
        assert r.status_code == 200
        devices = r.json()
        assert len(devices) == 1
        assert devices[0]["name"] == "TestPhone"
