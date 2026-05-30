"""
JobOfferUS icon — 1024×1024 RGBA
Fix: 4× supersampling + light circles (high contrast) + dark letters.
Circle A: light periwinkle (#C8C3FF) on dark bg → clearly visible.
Circle B: light lavender (#DEB8FF) on dark bg → clearly visible.
Letters: dark indigo (#16123C) on light circles → clearly readable.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

SIZE   = 1024
SUPER  = SIZE * 4          # 4096 — render at 4× then downscale
OUT    = "assets/images/icon.png"

# ── palette ──────────────────────────────────────────────────────────────────
BG_TOP    = (18,  15, 50)   # very dark indigo
BG_BOT    = (36,  20, 80)   # deep purple-navy
CIR_A     = (165, 158, 255) # light periwinkle — high contrast on dark bg
CIR_B     = (210, 165, 255) # light lavender   — high contrast on dark bg
LETTER    = (16,  12, 60)   # dark indigo — high contrast on light circles
AMBER     = (245, 158, 11)
AMBER_DARK= (120, 72, 0)    # dark text on amber bar

# ── 4× supersampled canvas ───────────────────────────────────────────────────
W = H = SUPER
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

# gradient bg
bg = Image.new("RGB", (W, H))
bd = ImageDraw.Draw(bg)
for y in range(H):
    t = y / (H - 1)
    r = int(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t)
    g = int(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t)
    b = int(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t)
    bd.line([(0, y), (W - 1, y)], fill=(r, g, b))
img.paste(bg)
img.putalpha(255)

# rounded-rect mask (iOS-style, radius = 224 @ 1× → 896 @ 4×)
mask = Image.new("L", (W, H), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, W-1, H-1], radius=896, fill=255)
img.putalpha(mask)
draw = ImageDraw.Draw(img)

# ── subtle centre glow ────────────────────────────────────────────────────────
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(glow).ellipse([W//4, H//4, 3*W//4, 3*H//4],
                               fill=(80, 60, 180, 30))
glow = glow.filter(ImageFilter.GaussianBlur(radius=300))
img = Image.alpha_composite(img, glow)
draw = ImageDraw.Draw(img)

# ── circles (at 4× scale) ─────────────────────────────────────────────────────
# Final image: circles at ≈230px radius, offset ±230px from centre
# At 4×: radius = 920, offset = 920
CY = H // 2 - 120   # shift slightly up
R  = 900
AX = W // 2 - 880
BX = W // 2 + 880

# white glow ring behind each circle for separation from bg
for cx_c, cy_c in [(AX, CY), (BX, CY)]:
    draw.ellipse([cx_c-R-24, cy_c-R-24, cx_c+R+24, cy_c+R+24],
                 fill=(255, 255, 255, 25))

draw.ellipse([AX-R, CY-R, AX+R, CY+R], fill=CIR_A)
draw.ellipse([BX-R, CY-R, BX+R, CY+R], fill=CIR_B)

# ── font loading ──────────────────────────────────────────────────────────────
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

fnt    = _load(880)   # 4× of 220
fnt_vs = _load(112)   # 4× of 28

def _draw_c(d, text, cx, cy, font, color):
    bb = d.textbbox((0, 0), text, font=font)
    tw, th = bb[2]-bb[0], bb[3]-bb[1]
    d.text((cx - tw//2 - bb[0], cy - th//2 - bb[1]), text, font=font, fill=color)

_draw_c(draw, "A", AX, CY, fnt, LETTER)
_draw_c(draw, "B", BX, CY, fnt, LETTER)

# ── amber VS bar ──────────────────────────────────────────────────────────────
BAR_W, BAR_H = 1840, 160
BAR_Y = CY + R + 220
CX = W // 2
draw.rounded_rectangle(
    [CX - BAR_W//2, BAR_Y, CX + BAR_W//2, BAR_Y + BAR_H],
    radius=80, fill=AMBER)
_draw_c(draw, "VS", CX, BAR_Y + BAR_H//2, fnt_vs, AMBER_DARK)

# ── border ring — crisp white glow ───────────────────────────────────────────
# Outer soft halo (3 layers, decreasing alpha)
for off, a in [(0, 55), (32, 30), (64, 12)]:
    draw.rounded_rectangle(
        [off, off, W-off, H-off],
        radius=896-off,
        outline=(220, 210, 255, a), width=24)

# Crisp bright ring at inset 40px (≈ 10px at 1×)
draw.rounded_rectangle(
    [40, 40, W-40, H-40],
    radius=856,
    outline=(255, 255, 255, 100), width=40)

# ── 4× → 1× downsample (LANCZOS antialiasing) ────────────────────────────────
final = img.resize((SIZE, SIZE), Image.LANCZOS)
os.makedirs("assets/images", exist_ok=True)
final.save(OUT, "PNG")
print(f"Icon saved: {OUT}  ({SIZE}x{SIZE})  [4x supersampled]")
