@echo off
:: Build script for PC Connector Agent EXE
:: Run this from the pc_agent directory or the repo root.
::
:: Requirements:
::   pip install pyinstaller
::   pip install -r pc_agent/requirements.txt

setlocal

:: Determine if we're already in pc_agent or in the repo root
if exist "main.py" (
    set "AGENT_DIR=%CD%"
) else if exist "pc_agent\main.py" (
    set "AGENT_DIR=%CD%\pc_agent"
) else (
    echo ERROR: Run this script from the repo root or the pc_agent folder.
    exit /b 1
)

cd /d "%AGENT_DIR%"

echo.
echo === Installing / verifying dependencies ===
pip install -r requirements.txt --quiet
pip install pyinstaller --quiet

echo.
echo === Building EXE ===
pyinstaller pc_connector.spec --noconfirm --clean

echo.
if exist "dist\PC_Connector_Agent.exe" (
    echo BUILD SUCCESSFUL
    echo Output: %AGENT_DIR%\dist\PC_Connector_Agent.exe
) else (
    echo BUILD FAILED - check output above.
    exit /b 1
)
