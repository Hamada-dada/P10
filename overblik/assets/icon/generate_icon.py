"""Generates app_icon.png (1024x1024).
Layout: dark navy bg, white calendar card, green header, family inside card outlined in black.
Family: two parents (taller) + one child (shorter, centred).
"""
from PIL import Image, ImageDraw

SIZE  = 1024
BG    = (26,  35,  64)    # #1A2340 dark navy
WHITE = (255, 255, 255)
GREEN = (162, 229, 173)   # #A2E5AD app green
BLACK = (15,  15,  15)    # near-black outline

img  = Image.new("RGB", (SIZE, SIZE), BG)
draw = ImageDraw.Draw(img)

# ── Calendar card ──────────────────────────────────────────────────────────
CL, CT, CR, CB = 80, 55, 944, 950
CARD_R   = 72       # card corner radius
HEADER_H = 168      # height of the green header

# White card background
draw.rounded_rectangle([CL, CT, CR, CB], radius=CARD_R, fill=WHITE)

# Green header – rounded top corners, square bottom
draw.rounded_rectangle([CL, CT, CR, CT + HEADER_H], radius=CARD_R, fill=GREEN)
draw.rectangle([CL, CT + HEADER_H - CARD_R, CR, CT + HEADER_H], fill=GREEN)

# Binding pegs (two rings on the very top edge)
for px in (CL + 222, CR - 222):
    py = CT + 22
    draw.ellipse([px-26, py-26, px+26, py+26], fill=BG)    # outer ring (navy)
    draw.ellipse([px-11, py-11, px+11, py+11], fill=WHITE)  # inner dot

# ── Family inside white body ───────────────────────────────────────────────
# body area: y from (CT + HEADER_H) = 223  to  CB = 950
FEET_Y = CB - 75   # 875 – bottom of all figures

OW = 10  # outline thickness


def draw_figure(cx, head_r, body_h):
    """Green figure with black outline: head + shoulder bulge + torso."""
    sw       = int(head_r * 1.58)   # shoulder half-width
    sh       = int(sw    * 0.50)    # shoulder ellipse half-height
    body_top = FEET_Y - body_h
    head_cy  = body_top - head_r    # head sits flush on body top

    # ── Black outline layer (draw each part expanded by OW) ────────────
    # Head outline
    draw.ellipse(
        [cx-head_r-OW, head_cy-head_r-OW,
         cx+head_r+OW, head_cy+head_r+OW],
        fill=BLACK,
    )
    # Shoulder outline
    draw.ellipse(
        [cx-sw-OW, body_top-sh-OW,
         cx+sw+OW, body_top+sh+OW],
        fill=BLACK,
    )
    # Torso outline (rectangle below shoulder bulge)
    draw.rectangle(
        [cx-sw-OW, body_top, cx+sw+OW, FEET_Y+OW],
        fill=BLACK,
    )

    # ── Green fill layer ────────────────────────────────────────────────
    # Head
    draw.ellipse(
        [cx-head_r, head_cy-head_r, cx+head_r, head_cy+head_r],
        fill=GREEN,
    )
    # Shoulder
    draw.ellipse(
        [cx-sw, body_top-sh, cx+sw, body_top+sh],
        fill=GREEN,
    )
    # Torso (starts at shoulder centre so there is no gap)
    draw.rectangle(
        [cx-sw, body_top, cx+sw, FEET_Y],
        fill=GREEN,
    )


# Draw order: parents first, child on top so it appears in front
draw_figure(cx=285, head_r=66, body_h=258)   # left parent
draw_figure(cx=739, head_r=66, body_h=258)   # right parent
draw_figure(cx=512, head_r=50, body_h=192)   # child (centred, shorter)

img.save("app_icon.png")
print(f"Saved app_icon.png  {img.size}  {img.mode}")
