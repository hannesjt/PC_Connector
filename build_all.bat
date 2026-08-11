@echo off
setlocal

set "APP_DIR=%~dp0web_app"

if not exist "%APP_DIR%\package.json" (
    echo ERROR: web_app\package.json not found. Run from the repo root.
    exit /b 1
)

cd /d "%APP_DIR%"

call npm install
if errorlevel 1 exit /b 1

node scripts/build-all.mjs %*
exit /b %errorlevel%
