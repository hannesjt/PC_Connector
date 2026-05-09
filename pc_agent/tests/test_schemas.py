"""Tests for Pydantic models / schemas."""

from models.schemas import (
    AppConfig,
    ApiConfig,
    AssignGroupRequest,
    ChainStep,
    PairingRequest,
    PairingResponse,
    PcConfig,
    ReorderRequest,
    ScriptChain,
    ScriptConfig,
    ScriptListItem,
    ScriptRunResponse,
    StatusResponse,
)


class TestScriptConfig:
    def test_defaults(self):
        s = ScriptConfig(id="x", name="X", command="echo hi")
        assert s.icon == "play_arrow"
        assert s.confirm is False
        assert s.timeout == 30
        assert s.group == ""
        assert s.order == 0
        assert s.is_global is False

    def test_all_fields(self):
        s = ScriptConfig(
            id="shutdown", name="Herunterfahren", command="shutdown /s /t 0",
            icon="power_off", confirm=True, timeout=10, group="System", order=3,
            is_global=True,
        )
        assert s.id == "shutdown"
        assert s.confirm is True
        assert s.group == "System"
        assert s.order == 3
        assert s.is_global is True


class TestAppConfig:
    def test_minimal(self):
        c = AppConfig(
            pc=PcConfig(name="PC", mac_address="AA-BB-CC-DD-EE-FF"),
            api=ApiConfig(),
        )
        assert c.pc.name == "PC"
        assert c.api.port == 8420
        assert c.scripts == []
        assert c.category_order == []

    def test_with_scripts(self):
        c = AppConfig(
            pc=PcConfig(name="PC", mac_address="AA-BB-CC-DD-EE-FF"),
            api=ApiConfig(port=9999),
            scripts=[
                ScriptConfig(id="a", name="A", command="echo a"),
                ScriptConfig(id="b", name="B", command="echo b"),
            ],
            category_order=["System", "Games"],
        )
        assert len(c.scripts) == 2
        assert c.category_order == ["System", "Games"]

    def test_api_config_ignores_extra(self):
        cfg = ApiConfig(**{"host": "0.0.0.0", "port": 8420, "unknown_field": True})
        assert cfg.port == 8420


class TestChainModels:
    def test_chain_step_defaults(self):
        step = ChainStep(script_id="s1")
        assert step.delay_seconds == 0

    def test_script_chain(self):
        chain = ScriptChain(
            id="morning",
            name="Morning Routine",
            steps=[
                ChainStep(script_id="s1", delay_seconds=5),
                ChainStep(script_id="s2"),
            ],
            order=1,
        )
        assert chain.name == "Morning Routine"
        assert len(chain.steps) == 2
        assert chain.steps[0].delay_seconds == 5
        assert chain.order == 1


class TestPairingModels:
    def test_pairing_request_defaults(self):
        r = PairingRequest(code="123456")
        assert r.device_name == "Unbekanntes Gerät"

    def test_pairing_response_success(self):
        r = PairingResponse(success=True, token="abc", message="ok")
        assert r.success is True
        assert r.token == "abc"

    def test_pairing_response_failure(self):
        r = PairingResponse(success=False, message="bad")
        assert r.token is None
        assert r.mac_address is None


class TestReorderRequest:
    def test_basic(self):
        r = ReorderRequest(ordered_ids=["c", "a", "b"])
        assert r.ordered_ids == ["c", "a", "b"]


class TestAssignGroupRequest:
    def test_without_old_group(self):
        r = AssignGroupRequest(group="System", script_ids=["a", "b"])
        assert r.old_group is None

    def test_with_old_group(self):
        r = AssignGroupRequest(group="New", script_ids=["a"], old_group="Old")
        assert r.old_group == "Old"


class TestScriptRunResponse:
    def test_defaults(self):
        r = ScriptRunResponse(script_id="x", success=True)
        assert r.stdout == ""
        assert r.stderr == ""
        assert r.exit_code == 0

    def test_full(self):
        r = ScriptRunResponse(
            script_id="x", success=False,
            stdout="out", stderr="err", exit_code=1,
        )
        assert r.exit_code == 1
