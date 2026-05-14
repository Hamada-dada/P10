"""Generates app_icon.png (1024x1024).

Two explicit visual layers:
  Layer 1 – calendar container
      white card, dark-green border, soft-green header, binding pegs,
      subtle dot grid (calendar dates)
  Layer 2 – family (drawn ON TOP of Layer 1)
      three avatar busts, soft-green fill, thin dark-green outline
      white separator ring around the child so it reads in front of the parents
      (same technique as the reference image)

No navy. No black fill on figures. No faces, text, gradients or shadows.
"""
from PIL import Image, ImageDraw

SIZE    = 1024
WHITE   = (255, 255, 255)
GREEN   = (162, 229, 173)   # #A2E5AD  header colour = family fill colour
DK_GRN  = (38,  138,  68)   # dark green for card border + figure outlines
DOT_C   = (200, 215, 228)   # muted blue-grey calendar dots
OW      = 10                 # outline width
C_SEP   = 9                  # extra white gap around child

img  = Image.new("RGB", (SIZE, SIZE), WHITE)
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# LAYER 1 – Calendar container
# ═══════════════════════════════════════════════════════════════════════════
CL, CT, CR, CB = 80, 55, 944, 950
CARD_R   = 72
HEADER_H = 160
BODY_TOP = CT + HEADER_H          # y = 215

# Card border (dark green stroke around the whole card)
draw.rounded_rectangle(
    [CL - 5, CT - 5, CR + 5, CB + 5], radius=CARD_R + 5, fill=DK_GRN
)
# White card body
draw.rounded_rectangle([CL, CT, CR, CB], radius=CARD_R, fill=WHITE)

# Green header – rounded top corners, flat bottom edge
draw.rounded_rectangle(
    [CL, CT, CR, CT + HEADER_H], radius=CARD_R, fill=GREEN
)
draw.rectangle(
    [CL, CT + HEADER_H - CARD_R, CR, CT + HEADER_H], fill=GREEN
)

# Binding pegs – dark outline ring / white centre
for px in (CL + 222, CR - 222):
    py = CT + 22
    draw.ellipse([px - 26, py - 26, px + 26, py + 26], fill=DK_GRN)
    draw.ellipse([px - 11, py - 11, px + 11, py + 11], fill=WHITE)

# Calendar dot grid (4 rows × 7 cols, sits in the upper body area)
DOT_R    = 8
GRID_TOP = BODY_TOP + 42          # y ≈ 257
ROW_H    = 46
LDX      = CL + 92
COL_STEP = (CR - CL - 184) / 6   # ≈ 113

for r in range(4):
    for c in range(7):
        dx = round(LDX + c * COL_STEP)
        dy = GRID_TOP + r * ROW_H
        fill = GREEN if (r == 1 and c == 3) else DOT_C
        draw.ellipse(
            [dx - DOT_R, dy - DOT_R, dx + DOT_R, dy + DOT_R], fill=fill
        )

# ═══════════════════════════════════════════════════════════════════════════
# LAYER 2 – Family (drawn LAST so they sit in front of the dots)
# ═══════════════════════════════════════════════════════════════════════════
# Each avatar = circular head  +  wide shallow shoulder dome.
# All share the same BASELINE (shoulder bottom) → equal footing.
# Child is shorter naturally because its head_r is smaller.

BASELINE = 870

# Parent sizes
P_HR, P_SW, P_SH = 132, 205, 150
# Child sizes
C_HR, C_SW, C_SH = 100, 154, 112

# Space parents so their shoulder edges barely touch / kiss at the midline
CENTRE   = SIZE // 2
P_CX     = CENTRE - P_SW + 8     # left  parent cx ≈ 315
Q_CX     = CENTRE + P_SW - 8     # right parent cx ≈ 709


def _ellipse(xy, fill):
    draw.ellipse(xy, fill=fill)


def bust(cx, hr, sw, sh, fill=GREEN, outline=DK_GRN):
    """Draw one avatar: outline pass (expanded) then fill pass (true size)."""
    sh_cy   = BASELINE - sh
    head_cy = sh_cy - hr

    # Outline layer – draw expanded shape in outline colour
    _ellipse([cx - sw - OW,  sh_cy - sh  - OW,
              cx + sw + OW,  sh_cy + sh  + OW], outline)
    _ellipse([cx - hr - OW, head_cy - hr - OW,
              cx + hr + OW, head_cy + hr + OW], outline)

    # Fill layer – draw true-size shape in fill colour
    _ellipse([cx - sw,  sh_cy - sh,  cx + sw,  sh_cy + sh ], fill)
    _ellipse([cx - hr, head_cy - hr, cx + hr, head_cy + hr], fill)


def white_ring(cx, hr, sw, sh, sep):
    """Draw a white halo around a figure (creates visual gap vs the parents)."""
    sh_cy   = BASELINE - sh
    head_cy = sh_cy - hr
    gap     = OW + sep

    _ellipse([cx - sw - gap,  sh_cy - sh  - gap,
              cx + sw + gap,  sh_cy + sh  + gap], WHITE)
    _ellipse([cx - hr - gap, head_cy - hr - gap,
              cx + hr + gap, head_cy + hr + gap], WHITE)


# ── Draw order ──────────────────────────────────────────────────────────────
# 1. Parents (behind)
bust(cx=P_CX, hr=P_HR, sw=P_SW, sh=P_SH)
bust(cx=Q_CX, hr=P_HR, sw=P_SW, sh=P_SH)

# 2. White separator ring around child (carves the child out from the parents,
#    exactly as in the reference image)
white_ring(cx=CENTRE, hr=C_HR, sw=C_SW, sh=C_SH, sep=C_SEP)

# 3. Child on top (foreground)
bust(cx=CENTRE, hr=C_HR, sw=C_SW, sh=C_SH)

img.save("app_icon.png")
print(f"Saved  {img.size}  {img.mode}")
