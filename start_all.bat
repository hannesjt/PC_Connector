@echo off
setlocal
cd /d "%~dp0web_app"

start "PC Connector Dev Server" cmd /k "npm run dev"

timeout /t 8 /nobreak >nul
start "" http://localhost:3000

npm run electron:dev
