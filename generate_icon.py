"""
Generates the PC Connector app icon as PNG (1024x1024) and ICO (256x256).
Requires: pip install Pillow
Output:
  assets/icon/icon.png   – used by flutter_launcher_icons
  assets/icon/icon.ico   – used by PyInstaller (Windows EXE)
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
OUT_DIR = Path(__file__).parent / "assets" / "icon"
OUT_DIR.mkdir(parents=True, exist_ok=True)

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# ── Background: rounded rect ─────────────────────────────
BG = (25, 118, 210)          # Material Blue 700
CORNER = SIZE // 5

def rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=fill)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=fill)
    draw.ellipse([x0, y0, x0 + 2*radius, y0 + 2*radius], fill=fill)
    draw.ellipse([x1 - 2*radius, y0, x1, y0 + 2*radius], fill=fill)
    draw.ellipse([x0, y1 - 2*radius, x0 + 2*radius, y1], fill=fill)
    draw.ellipse([x1 - 2*radius, y1 - 2*radius, x1, y1], fill=fill)

rounded_rect(draw, (0, 0, SIZE - 1, SIZE - 1), CORNER, BG)

# ── Monitor ──────────────────────────────────────────────
WHITE = (255, 255, 255, 255)
DARK  = (25, 118, 210)       # same as BG → cutout effect
LIGHT = (187, 222, 251)      # Blue 100

# Outer monitor frame
MX0, MY0, MX1, MY1 = 120, 160, 904, 640
rounded_rect(draw, (MX0, MY0, MX1, MY1), 40, WHITE)

# Screen (inner, dark)
SX0, SY0, SX1, SY1 = MX0 + 28, MY0 + 28, MX1 - 28, MY1 - 60
rounded_rect(draw, (SX0, SY0, SX1, SY1), 24, (13, 71, 161))   # Blue 900

# Monitor stand
draw.rectangle([472, MY1, 552, MY1 + 80], fill=WHITE)
rounded_rect(draw, (350, MY1 + 70, 674, MY1 + 110), 20, WHITE)

# ── Lightning bolt inside screen ─────────────────────────
BOLT = (255, 236, 64)    # amber
CX = (SX0 + SX1) // 2
CY = (SY0 + SY1) // 2
bolt_pts = [
    (CX + 60,  SY0 + 40),
    (CX - 20,  CY - 10),
    (CX + 20,  CY - 10),
    (CX - 60,  SY1 - 40),
    (CX + 10,  CY + 30),
    (CX - 30,  CY + 30),
]
draw.polygon(bolt_pts, fill=BOLT)

# ── Phone (right side) ───────────────────────────────────
PX0, PY0, PX1, PY1 = 720, 480, 860, 760
rounded_rect(draw, (PX0, PY0, PX1, PY1), 22, WHITE)
# screen
rounded_rect(draw, (PX0+10, PY0+24, PX1-10, PY1-24), 14, (13,71,161))
# home button
draw.ellipse([PX0+46, PY1-22, PX0+74, PY1-2], fill=LIGHT)

# ── Wifi arcs: phone → monitor (connection lines) ─────
ARC_COLOR = (187, 222, 251, 200)
cx, cy = 640, 620
for r in (50, 90, 130):
    bbox = [cx - r, cy - r, cx + r, cy + r]
    draw.arc(bbox, start=210, end=330, fill=ARC_COLOR, width=12)

# ── Save PNG ─────────────────────────────────────────────
png_path = OUT_DIR / "icon.png"
img.save(png_path, "PNG")
print(f"Saved {png_path}  ({SIZE}x{SIZE})")

# ── Save ICO (multi-size) ─────────────────────────────────
ico_path = OUT_DIR / "icon.ico"
sizes = [256, 128, 64, 48, 32, 16]
ico_imgs = [img.resize((s, s), Image.LANCZOS) for s in sizes]
ico_imgs[0].save(ico_path, format="ICO", sizes=[(s, s) for s in sizes],
                 append_images=ico_imgs[1:])
print(f"Saved {ico_path}  (multi-size ICO)")
