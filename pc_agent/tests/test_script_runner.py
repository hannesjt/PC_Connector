"""Tests for script_runner service."""

import asyncio

import pytest

from models.schemas import ScriptConfig
from services.script_runner import run_script


@pytest.fixture
def echo_script():
    return ScriptConfig(id="echo", name="Echo", command="echo hello", timeout=10)


@pytest.mark.asyncio
class TestRunScript:
    async def test_successful_script(self, echo_script):
        result = await run_script(echo_script)
        assert result.success is True
        assert result.exit_code == 0
        assert "hello" in result.stdout

    async def test_failing_script(self):
        script = ScriptConfig(id="fail", name="Fail", command="exit 1", timeout=10)
        result = await run_script(script)
        assert result.success is False
        assert result.exit_code != 0

    async def test_timeout(self):
        # Use a sleep that exceeds the timeout
        script = ScriptConfig(id="slow", name="Slow", command="ping -n 10 127.0.0.1", timeout=1)
        result = await run_script(script)
        assert result.success is False
        assert "timed out" in result.stderr.lower()

    async def test_stderr_capture(self):
        script = ScriptConfig(id="err", name="Err", command="echo error>&2", timeout=10)
        result = await run_script(script)
        assert result.script_id == "err"
