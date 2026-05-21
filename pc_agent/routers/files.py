"""File explorer endpoints – browse, download, upload files on the PC."""

from __future__ import annotations

import os
from pathlib import Path

from fastapi import APIRouter, UploadFile, File, Query
from fastapi.responses import FileResponse
from pydantic import BaseModel

router = APIRouter(prefix="/api/files", tags=["files"])


class FileEntry(BaseModel):
    name: str
    path: str
    is_dir: bool
    size: int = 0
    modified: float = 0.0


@router.get("/list", response_model=list[FileEntry])
async def list_directory(path: str = Query(default="")):
    """List contents of a directory. Empty path = user home drives overview."""
    if not path:
        # Return available drives on Windows, home on Linux
        import sys
        if sys.platform == "win32":
            import string
            entries = []
            for letter in string.ascii_uppercase:
                drive = f"{letter}:\\"
                if os.path.exists(drive):
                    entries.append(FileEntry(
                        name=drive,
                        path=drive,
                        is_dir=True,
                    ))
            return entries
        else:
            path = str(Path.home())

    target = Path(path)
    if not target.exists() or not target.is_dir():
        return []

    entries: list[FileEntry] = []
    try:
        for item in sorted(target.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower())):
            try:
                stat = item.stat()
                entries.append(FileEntry(
                    name=item.name,
                    path=str(item),
                    is_dir=item.is_dir(),
                    size=stat.st_size if not item.is_dir() else 0,
                    modified=stat.st_mtime,
                ))
            except (PermissionError, OSError):
                continue
    except PermissionError:
        pass
    return entries


@router.get("/download")
async def download_file(path: str = Query(...)):
    """Download a file from the PC."""
    file_path = Path(path)
    if not file_path.exists() or not file_path.is_file():
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Datei nicht gefunden")
    return FileResponse(
        path=str(file_path),
        filename=file_path.name,
        media_type="application/octet-stream",
    )


@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    dest: str = Query(..., description="Destination directory path"),
):
    """Upload a file to a directory on the PC."""
    dest_dir = Path(dest)
    if not dest_dir.exists() or not dest_dir.is_dir():
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="Zielverzeichnis existiert nicht")

    target_path = dest_dir / file.filename
    content = await file.read()
    target_path.write_bytes(content)
    return {"success": True, "path": str(target_path), "size": len(content)}


@router.post("/open")
async def open_file(path: str = Query(...)):
    """Open a file with the default application on the PC."""
    import subprocess
    import sys
    file_path = Path(path)
    if not file_path.exists():
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Datei nicht gefunden")

    if sys.platform == "win32":
        os.startfile(str(file_path))
    else:
        subprocess.Popen(["xdg-open", str(file_path)])
    return {"success": True}
