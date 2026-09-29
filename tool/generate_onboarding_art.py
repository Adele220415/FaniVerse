#!/usr/bin/env python3
"""Generates the onboarding card illustrations in assets/onboarding/.

Three wide illustrations, one per onboarding page, sharing the app palette
(#7C5CFF primary, #8B6FFF light, #2A2348 tint, #DBDADF ink) and a single
800x520 viewBox so the carousel does not reflow between pages.

Run from the project root:

    python tool/generate_onboarding_art.py
"""

from __future__ import annotations

import os
import textwrap

W, H = 800, 520
OUT_DIR = os.path.join("assets", "onboarding")

PRIMARY = "#7C5CFF"
LIGHT = "#8B6FFF"
TINT = "#2A2348"
DEEP = "#121214"
INK = "#DBDADF"
MUTED = "#8D8C92"
ACCENT = "#FF5A5A"
SUCCESS = "#3DD68C"


def svg(body: str) -> str:
    # `body` is interpolated before dedent runs, so dedent only sees the shell's
    # own indentation. Dedenting the two parts separately and joining them keeps
    # the output flush-left, which matters because these files are committed
    # and should diff cleanly.
    inner = textwrap.indent(textwrap.dedent(body).strip(), "  ")
    header = (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}"\n'
        f'     width="{W}" height="{H}" role="img">\n'
    )
    return header + inner + "\n</svg>\n"


def panel(x: int, y: int, w: int, h: int, fill: str = TINT, radius: int = 18, opacity: float = 1.0) -> str:
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" '
        f'fill="{fill}" fill-opacity="{opacity}"/>'
    )


# ---------------------------------------------------------------------------
# 1. Discover - a stack of content cards fanning out
# ---------------------------------------------------------------------------

DISCOVER = f"""
<defs>
  <linearGradient id="glow" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0%" stop-color="{PRIMARY}" stop-opacity="0.35"/>
    <stop offset="100%" stop-color="{PRIMARY}" stop-opacity="0"/>
  </linearGradient>
</defs>

<circle cx="400" cy="250" r="230" fill="url(#glow)"/>

<!-- Back cards, rotated for depth -->
<g transform="rotate(-9 400 260)">{panel(210, 120, 380, 250, TINT, 20, 0.55)}</g>
<g transform="rotate(8 400 260)">{panel(210, 120, 380, 250, TINT, 20, 0.75)}</g>

<!-- Front card -->
{panel(196, 108, 408, 274, TINT, 22)}
{panel(220, 132, 172, 120, PRIMARY, 14)}
<path d="M232 236l34-40 26 30 22-24 30 34z" fill="{LIGHT}"/>
<circle cx="262" cy="160" r="14" fill="{LIGHT}"/>

{panel(410, 136, 170, 14, MUTED, 7, 0.7)}
{panel(410, 162, 120, 12, MUTED, 6, 0.45)}
{panel(220, 272, 360, 12, MUTED, 6, 0.4)}
{panel(220, 296, 250, 12, MUTED, 6, 0.3)}

<!-- Category chips, echoing the app's filter row -->
{panel(220, 328, 84, 30, PRIMARY, 15)}
{panel(316, 328, 84, 30, "#23232A", 15)}
{panel(412, 328, 84, 30, "#23232A", 15)}
<circle cx="242" cy="343" r="9" fill="{LIGHT}"/>
<circle cx="338" cy="343" r="9" fill="{MUTED}"/>
<circle cx="434" cy="343" r="9" fill="{MUTED}"/>
"""


# ---------------------------------------------------------------------------
# 2. Events - a calendar with pinned events
# ---------------------------------------------------------------------------

EVENTS = f"""
<defs>
  <linearGradient id="glow2" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0%" stop-color="{ACCENT}" stop-opacity="0.28"/>
    <stop offset="100%" stop-color="{ACCENT}" stop-opacity="0"/>
  </linearGradient>
</defs>

<circle cx="400" cy="250" r="230" fill="url(#glow2)"/>

<!-- Calendar body -->
{panel(206, 108, 388, 304, TINT, 22)}
{panel(206, 108, 388, 62, PRIMARY, 22)}
<rect x="206" y="146" width="388" height="24" fill="{PRIMARY}"/>

<!-- Binder rings -->
<rect x="256" y="88" width="16" height="46" rx="8" fill="{LIGHT}"/>
<rect x="392" y="88" width="16" height="46" rx="8" fill="{LIGHT}"/>
<rect x="528" y="88" width="16" height="46" rx="8" fill="{LIGHT}"/>

<!-- Grid of days -->
<g fill="{MUTED}" fill-opacity="0.28">
  <rect x="236" y="196" width="34" height="30" rx="8"/>
  <rect x="284" y="196" width="34" height="30" rx="8"/>
  <rect x="332" y="196" width="34" height="30" rx="8"/>
  <rect x="380" y="196" width="34" height="30" rx="8"/>
  <rect x="236" y="240" width="34" height="30" rx="8"/>
  <rect x="284" y="240" width="34" height="30" rx="8"/>
  <rect x="332" y="240" width="34" height="30" rx="8"/>
  <rect x="380" y="240" width="34" height="30" rx="8"/>
  <rect x="236" y="284" width="34" height="30" rx="8"/>
  <rect x="284" y="284" width="34" height="30" rx="8"/>
</g>

<!-- Marked days -->
{panel(332, 196, 34, 30, ACCENT, 8)}
{panel(236, 284, 34, 30, SUCCESS, 8)}
{panel(428, 196, 34, 30, PRIMARY, 8)}
{panel(476, 240, 34, 30, PRIMARY, 8)}
<path d="M340 211l6 7 12-14" stroke="{DEEP}" stroke-width="5" fill="none"
      stroke-linecap="round" stroke-linejoin="round"/>
<path d="M244 299l6 7 12-14" stroke="{DEEP}" stroke-width="5" fill="none"
      stroke-linecap="round" stroke-linejoin="round"/>

<!-- Event card pulled out of the calendar -->
{panel(452, 316, 196, 76, "#23232A", 16)}
<rect x="452" y="316" width="6" height="76" rx="3" fill="{PRIMARY}"/>
{panel(474, 336, 100, 12, MUTED, 6, 0.7)}
{panel(474, 358, 66, 10, MUTED, 5, 0.4)}

<!-- Location pin -->
<path d="M540 196a22 22 0 1 0-44 0c0 20 44 46 44 46s44-26 44-46a22 22 0 0 0-22-22z"
      fill="{ACCENT}"/>
<circle cx="518" cy="196" r="9" fill="{DEEP}"/>
"""


# ---------------------------------------------------------------------------
# 3. Shop / save / AI - a product, a saved badge and a chat bubble
# ---------------------------------------------------------------------------

SHOP = f"""
<defs>
  <linearGradient id="glow3" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0%" stop-color="{PRIMARY}" stop-opacity="0.32"/>
    <stop offset="100%" stop-color="{LIGHT}" stop-opacity="0"/>
  </linearGradient>
</defs>

<circle cx="400" cy="250" r="230" fill="url(#glow3)"/>

<!-- Product card -->
{panel(150, 116, 250, 280, TINT, 22)}
{panel(172, 140, 206, 140, PRIMARY, 16)}
<path d="M232 244l34-44 30 34 24-26 36 36z" fill="{LIGHT}"/>
<circle cx="220" cy="178" r="18" fill="{LIGHT}"/>
{panel(172, 300, 150, 14, MUTED, 7, 0.6)}
{panel(172, 326, 96, 20, SUCCESS, 10)}
{panel(172, 356, 70, 12, MUTED, 6, 0.35)}
<circle cx="188" cy="366" r="4" fill="{DEEP}"/>
<circle cx="200" cy="366" r="4" fill="{DEEP}"/>
<circle cx="212" cy="366" r="4" fill="{DEEP}"/>

<!-- Add-to-cart button -->
{panel(152, 348, 120, 34, PRIMARY, 17)}
<path d="M182 362v10M177 367h10" stroke="{DEEP}" stroke-width="5" stroke-linecap="round"/>

<!-- Saved / offline badge -->
{panel(430, 100, 176, 60, "#23232A", 18)}
<path d="M462 118h20c6 0 10 4 10 10v18c0 6-4 10-10 10h-20c-6 0-10-4-10-10v-18c0-6 4-10 10-10z"
      fill="{SUCCESS}"/>
{panel(504, 124, 84, 12, MUTED, 6, 0.6)}

<!-- AI chat bubble -->
{panel(360, 196, 300, 128, TINT, 24)}
<path d="M420 324l-8 40 48-40z" fill="{TINT}"/>
{panel(392, 228, 200, 16, LIGHT, 8)}
{panel(392, 258, 236, 12, MUTED, 6, 0.45)}
{panel(392, 282, 160, 12, MUTED, 6, 0.3)}

<!-- Sparkles, the AI cue -->
<path d="M330 132l6 16 16 6-16 6-6 16-6-16-16-6 16-6z" fill="{LIGHT}"/>
<path d="M660 250l5 13 13 5-13 5-5 13-5-13-13-5 13-5z" fill="{PRIMARY}"/>
<path d="M690 150l4 10 10 4-10 4-4 10-4-10-10-4 10-4z" fill="{LIGHT}"
      fill-opacity="0.7"/>
"""


ILLUSTRATIONS = {
    "discover": DISCOVER,
    "events": EVENTS,
    "shop": SHOP,
}


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)

    for name, body in ILLUSTRATIONS.items():
        path = os.path.join(OUT_DIR, f"{name}.svg")
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(svg(body))
        print(f"  wrote {path}")

    print(f"\n{len(ILLUSTRATIONS)} onboarding illustrations written to {OUT_DIR}/")


if __name__ == "__main__":
    main()
