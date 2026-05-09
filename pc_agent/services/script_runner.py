import asyncio
import subprocess

from models.schemas import ScriptConfig, ScriptRunResponse


async def run_script(script: ScriptConfig) -> ScriptRunResponse:
    try:
        proc = await asyncio.wait_for(
            _execute(script.command),
            timeout=script.timeout,
        )
        return ScriptRunResponse(
            script_id=script.id,
            success=proc.returncode == 0,
            exit_code=proc.returncode,
            stdout=proc.stdout,
            stderr=proc.stderr,
        )
    except asyncio.TimeoutError:
        return ScriptRunResponse(
            script_id=script.id,
            success=False,
            exit_code=-1,
            stdout="",
            stderr=f"Script timed out after {script.timeout}s",
        )
    except Exception as e:
        return ScriptRunResponse(
            script_id=script.id,
            success=False,
            exit_code=-1,
            stdout="",
            stderr=str(e),
        )


async def _execute(command: str) -> subprocess.CompletedProcess:
    proc = await asyncio.create_subprocess_shell(
        command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout_bytes, stderr_bytes = await proc.communicate()
    return subprocess.CompletedProcess(
        args=command,
        returncode=proc.returncode or 0,
        stdout=stdout_bytes.decode("utf-8", errors="replace").strip(),
        stderr=stderr_bytes.decode("utf-8", errors="replace").strip(),
    )
