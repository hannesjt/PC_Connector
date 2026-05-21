# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec for PC Connector Agent
# Build with: pyinstaller pc_connector.spec

import sys
from pathlib import Path
from PyInstaller.utils.hooks import collect_all

block_cipher = None

_mp_datas, _mp_binaries, _mp_hidden = collect_all('multipart')

a = Analysis(
    ['main.py'],
    pathex=['.'],
    binaries=[] + _mp_binaries,
    datas=[
        ('templates', 'templates'),
        ('config.yaml.example', '.'),
        ('../assets/icon/icon.png', '.'),
    ] + _mp_datas,
    hiddenimports=[
        # uvicorn internals
        'uvicorn.logging',
        'uvicorn.loops',
        'uvicorn.loops.auto',
        'uvicorn.loops.asyncio',
        'uvicorn.loops.uvloop',
        'uvicorn.protocols',
        'uvicorn.protocols.http',
        'uvicorn.protocols.http.auto',
        'uvicorn.protocols.http.h11_impl',
        'uvicorn.protocols.http.httptools_impl',
        'uvicorn.protocols.websockets',
        'uvicorn.protocols.websockets.auto',
        'uvicorn.protocols.websockets.websockets_impl',
        'uvicorn.protocols.websockets.wsproto_impl',
        'uvicorn.lifespan',
        'uvicorn.lifespan.on',
        'uvicorn.lifespan.off',
        # FastAPI / starlette
        'starlette.routing',
        'starlette.middleware',
        'starlette.responses',
        'starlette.requests',
        'starlette.templating',
        # Pydantic
        'pydantic.deprecated.class_validators',
        # encodings
        'encodings.idna',
        # pystray (system tray)
        'pystray._win32',
        'PIL._tkinter_finder',
        # pyautogui (mouse & keyboard control)
        'pyautogui',
        'pynput',
        'pynput.mouse',
        'pynput.keyboard',
        'mouseinfo',
        # file upload support
        'multipart',
        'multipart.multipart',
        # volume control
        'pycaw',
        'pycaw.pycaw',
        'comtypes',
        'comtypes.client',
        'comtypes.server',
        'comtypes.persist',
        # clipboard
        'pyperclip',
        'pyperclip.clipboard',
    ] + _mp_hidden,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='PC_Connector_Agent',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,         # no console window – app lives in the system tray
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='../assets/icon/icon.ico',
)
