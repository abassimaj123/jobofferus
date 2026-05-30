"""
Generate JobOfferUS splash screen logo — 512×512 PNG (transparent bg)
Larger size → sharper on high-DPI devices.
Includes app name text below the A/B circles.
"""
from PIL import Image, ImageDraw, ImageFont
import os

SIZE   = 512
OUT    = "assets/images/splash_logo.png"
IND_LT = (100, 88, 250)
VIO_LT = (167, 107, 243)
AMBER  = (245, 158, 11)
WHITE  = (255, 255, 255)
DARK   = (22,  19, 60)

img  = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

cx  = SIZE // 2
cy  = 185          # circle vertical center (upper area)
r   = 108          # circle radius
gap = 28           # gap between circles

ax = cx - r - gap // 2
bx = cx + r + gap // 2

draw.ellipse([ax - r, cy - r, ax + r, cy + r], fill=IND_LT)
draw.ellipse([bx - r, cy - r, bx + r, cy + r], fill=VIO_LT)

# ── font loading ─────────────────────────────────────────────────────────
def _load(size):
    for p in [
        "C:/Windows/Fonts/ariblk.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
        "arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            pass
    return ImageFont.load_default()

fnt_letter = _load(130)
fnt_vs     = _load(16)
fnt_name   = _load(42)
fnt_tag    = _load(20)

def _center(d, text, cx, cy, font, color):
    bb = d.textbbox((0, 0), text, font=font)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    d.text((cx - tw // 2 - bb[0], cy - th // 2 - bb[1]),
           text, font=font, fill=color)

_center(draw, "A", ax, cy, fnt_letter, WHITE)
_center(draw, "B", bx, cy, fnt_letter, WHITE)

# ── amber VS strip ────────────────────────────────────────────────────────
bar_y   = cy + r + 24
bar_w   = 260
bar_h   = 22
draw.rounded_rectangle(
    [cx - bar_w // 2, bar_y, cx + bar_w // 2, bar_y + bar_h],
    radius=11, fill=AMBER)
_center(draw, "VS", cx, bar_y + bar_h // 2, fnt_vs, DARK)

# ── app name: "Job Offer US" (white + amber "US") ─────────────────────────
name_y = bar_y + bar_h + 32

# Measure each part to build a combined centered line
bb_jo = draw.textbbox((0, 0), "Job Offer ", font=fnt_name)
bb_us = draw.textbbox((0, 0), "US",        font=fnt_name)
total_w = (bb_jo[2] - bb_jo[0]) + (bb_us[2] - bb_us[0])
start_x = cx - total_w // 2

draw.text((start_x - bb_jo[0], name_y - bb_jo[1]),
          "Job Offer ", font=fnt_name, fill=WHITE)
draw.text((start_x + (bb_jo[2] - bb_jo[0]) - bb_us[0],
           name_y - bb_us[1]),
          "US", font=fnt_name, fill=AMBER)

# ── tagline ───────────────────────────────────────────────────────────────
tag_y = name_y + (bb_jo[3] - bb_jo[1]) + 10
_center(draw, "True After-Tax Comparison",
        cx, tag_y, fnt_tag, (200, 195, 255))

# ── save ──────────────────────────────────────────────────────────────────
os.makedirs("assets/images", exist_ok=True)
img.save(OUT, "PNG")
print(f"Splash logo saved: {OUT}  ({SIZE}x{SIZE})")
