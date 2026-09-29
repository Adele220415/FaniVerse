"""Renders the FaniVerse app icon.

The reference artwork is a gradient emblem - a violet/gold ring, a teal cog, a
cream star and a violet-to-gold orbital swoosh - on a rounded deep-purple tile.

There is no image library for SVG on this machine (no rsvg, no Inkscape, no
ImageMagick), so the geometry is drawn directly with Pillow and everything is
rendered at 4x then downsampled. Supersampling is what gives the diagonal
swoosh and the cog teeth clean anti-aliased edges; drawing at 1x would leave
visible stair-stepping on every curve.

    python tool/generate_app_icon.py

Writes:
    assets/branding/app_icon.png         1024x1024, rounded tile  (launcher)
    assets/branding/app_icon_maskable.png 1024x1024, padded+filled (PWA maskable)
    assets/branding/app_icon_foreground.png 1024x1024, emblem only, no tile

To use the real artwork instead of this reconstruction, drop a 1024x1024 PNG at
assets/branding/app_icon_source.png and re-run `python tool/generate_app_icon.py
--from-source`, or skip straight to `dart run flutter_launcher_icons`.
"""

import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

SS = 4  # supersample factor
SIZE = 1024
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "branding")

# Palette, sampled from the reference.
BG_TOP = (32, 15, 74)
BG_BOTTOM = (13, 6, 34)
VIOLET = (139, 92, 246)
VIOLET_LIGHT = (168, 85, 247)
GOLD = (240, 201, 135)
GOLD_DEEP = (217, 164, 65)
TEAL = (45, 212, 191)
CREAM = (245, 208, 192)


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def vertical_gradient(size, top, bottom):
    """A vertical linear gradient as an RGB image."""
    grad = Image.new("RGB", (1, size))
    px = grad.load()
    for y in range(size):
        px[0, y] = lerp(top, bottom, y / max(1, size - 1))
    return grad.resize((size, size), Image.NEAREST)


def diagonal_gradient(width, height, start, end, angle_deg=25.0, steps=192):
    """A linear gradient along an arbitrary angle, as an RGB image.

    Rendered on a small grid and then upscaled. The source is a linear ramp, so
    bilinear rescaling reproduces it in appearance while cutting the per-pixel
    work by three orders of magnitude - doing it per pixel on the supersampled
    canvas is ~16M Python iterations and takes minutes.
    """
    small = Image.new("RGB", (steps, steps))
    px = small.load()
    rad = math.radians(angle_deg)
    dx, dy = math.cos(rad), math.sin(rad)
    # Project each pixel onto the gradient axis, measured from the centre, and
    # normalise across the axis' full extent. Offsetting by the centre rather
    # than clamping the origin is what makes negative dx/dy work - an
    # origin-anchored formula saturates the whole image to one end.
    half = (steps - 1) / 2.0
    denom = half * (abs(dx) + abs(dy))
    for y in range(steps):
        for x in range(steps):
            t = ((x - half) * dx + (y - half) * dy) / denom + 0.5
            px[x, y] = lerp(start, end, max(0.0, min(1.0, t)))
    return small.resize((width, height), Image.BICUBIC)


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def ring_arc_mask(size, outer, inner, start_deg, end_deg):
    """An annulus segment between two angles (0 = 3 o'clock, clockwise)."""
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    steps = max(8, int(abs(end_deg - start_deg)))
    for i in range(steps):
        a0 = start_deg + (end_deg - start_deg) * i / steps
        a1 = start_deg + (end_deg - start_deg) * (i + 1) / steps
        d.pieslice(
            [size / 2 - outer, size / 2 - outer, size / 2 + outer, size / 2 + outer],
            a0, a1, fill=255,
        )
    # Punch the hole back out.
    d.ellipse(
        [size / 2 - inner, size / 2 - inner, size / 2 + inner, size / 2 + inner],
        fill=0,
    )
    return mask


def gear_mask(size, radius, teeth, tooth_depth, tooth_width_deg):
    """A cog: a disc with radial teeth around the rim."""
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    c = size / 2
    d.ellipse([c - radius, c - radius, c + radius, c + radius], fill=255)

    step = 360.0 / teeth
    for i in range(teeth):
        a0 = i * step - tooth_width_deg / 2
        a1 = i * step + tooth_width_deg / 2
        d.pieslice(
            [c - radius - tooth_depth, c - radius - tooth_depth,
             c + radius + tooth_depth, c + radius + tooth_depth],
            a0, a1, fill=255,
        )
    return mask


def star_points(cx, cy, points, outer_r, inner_r, rotation=-90):
    """Vertices of an n-pointed star, alternating outer and inner radius."""
    pts = []
    for i in range(points * 2):
        r = outer_r if i % 2 == 0 else inner_r
        a = math.radians(rotation + i * 180.0 / points)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def paste_gradient(base, gradient, mask):
    """Composite `gradient` onto `base` through `mask`."""
    base.paste(gradient, (0, 0), mask)


def build_emblem(size):
    """The emblem alone, transparent background, centred.

    Kept square and edge-to-edge so it can be used as an iOS foreground layer,
    where the platform applies its own corner rounding and the artwork must be
    inset rather than pre-rounded.
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    c = size / 2

    # --- outer ring, split into two arcs with gaps -------------------
    # Sized so the ring reads as a distinct band around the cog rather than
    # merging into it: the cog's teeth stop well inside the ring's inner edge.
    ring_outer = size * 0.320
    ring_inner = size * 0.248

    violet_arc = ring_arc_mask(size, ring_outer, ring_inner, 186, 274)
    paste_gradient(img, diagonal_gradient(size, size, VIOLET, VIOLET_LIGHT, 300), violet_arc)

    gold_arc = ring_arc_mask(size, ring_outer, ring_inner, 6, 94)
    paste_gradient(img, diagonal_gradient(size, size, GOLD_DEEP, GOLD, 60), gold_arc)

    # --- teal cog -----------------------------------------------------
    # Body 0.145 + teeth 0.038 reaches 0.183, clearing the ring's inner edge at
    # 0.248 with room to spare. Oversized teeth here are what made an earlier
    # pass read as a solid blob with a ring stuck to the outside.
    cog = gear_mask(size, size * 0.145, 11, size * 0.038, 16)
    # The cog sits slightly left of centre in the reference, because the gold
    # arc crowds the right side.
    cog = cog.crop((int(size * 0.03), 0, int(size * 0.97), size))
    cog = cog.resize((size, size), Image.LANCZOS)
    paste_gradient(img, diagonal_gradient(size, size, (56, 226, 205), TEAL, 120), cog)

    # --- cream star ---------------------------------------------------
    star = Image.new("L", (size, size), 0)
    ImageDraw.Draw(star).polygon(
        star_points(size * 0.468, size * 0.492, 8, size * 0.112, size * 0.040),
        fill=255,
    )
    paste_gradient(img, diagonal_gradient(size, size, (252, 226, 214), CREAM, 200), star)

    # --- orbital swoosh ------------------------------------------------
    # Two ellipse arcs, one drawn behind the emblem and one in front, which is
    # what produces the over/under weave at the left and right edges. The
    # gradient runs left-to-right so the violet end sits on the violet arc.
    swoosh_back = Image.new("L", (size, size), 0)
    sw = size * 0.395
    sh = size * 0.140
    box = [c - sw, c - sh, c + sw, c + sh]
    stroke = max(1, int(size * 0.018))
    ImageDraw.Draw(swoosh_back).arc(box, 8, 168, fill=255, width=stroke)
    swoosh_back = swoosh_back.rotate(-19, resample=Image.BICUBIC, center=(c, c))

    swoosh_front = Image.new("L", (size, size), 0)
    ImageDraw.Draw(swoosh_front).arc(box, 188, 348, fill=255, width=stroke)
    swoosh_front = swoosh_front.rotate(-19, resample=Image.BICUBIC, center=(c, c))

    gradient = diagonal_gradient(size, size, VIOLET_LIGHT, GOLD, 0)
    paste_gradient(img, gradient, swoosh_back)
    paste_gradient(img, gradient, swoosh_front)

    # --- corner accents -------------------------------------------------
    # Gold at the top right against the gold arc, violet at the bottom left
    # against the violet one, so the accents reinforce the ring rather than
    # fighting it.
    top_right = Image.new("L", (size, size), 0)
    ImageDraw.Draw(top_right).polygon(
        [(size * 0.795, size * 0.105), (size * 0.900, size * 0.105),
         (size * 0.900, size * 0.200)], fill=255)
    paste_gradient(img, diagonal_gradient(size, size, GOLD_DEEP, GOLD, 90), top_right)

    bottom_left = Image.new("L", (size, size), 0)
    ImageDraw.Draw(bottom_left).polygon(
        [(size * 0.130, size * 0.805), (size * 0.240, size * 0.805),
         (size * 0.130, size * 0.900)], fill=255)
    paste_gradient(img, diagonal_gradient(size, size, VIOLET, VIOLET_LIGHT, 90), bottom_left)

    return img


def build_tile(size, padding=0.0, opaque_bg=True):
    """The rounded tile. `padding` insets the emblem for a maskable icon."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tile = vertical_gradient(size, BG_TOP, BG_BOTTOM).convert("RGBA")
    img.paste(tile, (0, 0), rounded_mask(size, int(size * 0.225)))

    if padding <= 0:
        emblem = build_emblem(size)
    else:
        inner = int(size * (1 - padding * 2))
        emblem = build_emblem(inner)
        img.paste(emblem, ((size - inner) // 2, (size - inner) // 2), emblem)

    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), img)
    if not opaque_bg:
        out.putalpha(255)
    return out


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    from_source = "--from-source" in sys.argv
    source = os.path.join(OUT_DIR, "app_icon_source.png")

    if from_source:
        if not os.path.exists(source):
            sys.exit(f"--from-source given but {source} does not exist")
        base = Image.open(source).convert("RGBA").resize((SIZE, SIZE), Image.LANCZOS)
        base.save(os.path.join(OUT_DIR, "app_icon.png"))
        print("Used app_icon_source.png for app_icon.png")
        return

    print(f"Rendering at {SIZE * SS}x{SIZE * SS} then downsampling...")

    emblem = build_emblem(SIZE * SS)
    tile = Image.new("RGBA", (SIZE * SS, SIZE * SS), (0, 0, 0, 0))
    background = vertical_gradient(SIZE * SS, BG_TOP, BG_BOTTOM).convert("RGBA")
    tile.paste(background, (0, 0), rounded_mask(SIZE * SS, int(SIZE * SS * 0.225)))
    tile.paste(emblem, (0, 0), emblem)
    tile = tile.resize((SIZE, SIZE), Image.LANCZOS)
    tile.save(os.path.join(OUT_DIR, "app_icon.png"))
    print("  app_icon.png")

    # Maskable: Android and the PWA crop this to a circle on some launchers, so
    # the emblem is inset and the background is filled edge to edge.
    maskable = Image.new("RGBA", (SIZE, SIZE), BG_BOTTOM + (255,))
    inner = int(SIZE * 0.62)
    small = build_emblem(inner).resize((inner, inner), Image.LANCZOS)
    maskable.paste(small, ((SIZE - inner) // 2, (SIZE - inner) // 2), small)
    maskable.save(os.path.join(OUT_DIR, "app_icon_maskable.png"))
    print("  app_icon_maskable.png")

    build_emblem(SIZE).save(os.path.join(OUT_DIR, "app_icon_foreground.png"))
    print("  app_icon_foreground.png")


if __name__ == "__main__":
    main()
