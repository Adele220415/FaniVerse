#!/usr/bin/env python3
"""Generates the category illustrations in assets/categories/.

One flat-design SVG per fandom, all sharing a single 400x400 viewBox and the
same three-colour palette as the app (#7C5CFF primary, #8B6FFF light,
#2A2348 tint) so the set reads as one family rather than eleven unrelated
pictures.

Run from the project root:

    python tool/generate_category_art.py

Each motif is drawn from primitives only - circles, rounded rects, polygons and
strokes - so the output stays small and stays editable.
"""

from __future__ import annotations

import os
from textwrap import dedent

VIEWBOX = 400
OUT_DIR = os.path.join("assets", "categories")

PRIMARY = "#7C5CFF"
LIGHT = "#8B6FFF"
TINT = "#2A2348"
DEEP = "#121214"
WHITE = "#DBDADF"


def svg(body: str) -> str:
    """Wrap a motif in the shared document shell."""
    return dedent(
        f"""\
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {VIEWBOX} {VIEWBOX}"
             width="{VIEWBOX}" height="{VIEWBOX}" role="img">
          {dedent(body).strip()}
        </svg>
        """
    )


# ---------------------------------------------------------------------------
# Motifs
# ---------------------------------------------------------------------------
# Each returns only the inner markup; the circular backdrop is added once by
# `artwork()` so every tile is compositionally identical.

MOTIFS = {
    "anime": """
        <circle cx="200" cy="168" r="62" fill="{PRIMARY}"/>
        <path d="M200 96c34 0 62 28 62 62 0 10-2 19-6 28-6-30-24-46-56-46s-50 16-56 46c-4-9-6-18-6-28 0-34 28-62 62-62z" fill="{LIGHT}"/>
        <circle cx="178" cy="170" r="8" fill="{DEEP}"/>
        <circle cx="222" cy="170" r="8" fill="{DEEP}"/>
        <path d="M182 202c10 12 26 12 36 0" stroke="{DEEP}" stroke-width="7" fill="none" stroke-linecap="round"/>
        <path d="M150 258h100l-50 44z" fill="{LIGHT}"/>
    """,
    "donghua": """
        <path d="M60 288l80-150 52 96 44-70 104 124z" fill="{PRIMARY}"/>
        <path d="M60 288l80-150 30 56-52 94z" fill="{LIGHT}"/>
        <path d="M248 214c14-26 40-30 54-12 8 10 6 24-2 32-14 14-40 12-52-4z" fill="{DEEP}"/>
        <rect x="196" y="150" width="46" height="34" rx="4" fill="{DEEP}"/>
        <path d="M196 162c-16 0-28 8-32 18h64c-4-10-16-18-32-18z" fill="{DEEP}"/>
        <circle cx="276" cy="120" r="26" fill="{LIGHT}"/>
    """,
    "manga": """
        <path d="M78 116h244v176a12 12 0 0 1-12 12H90a12 12 0 0 1-12-12z" fill="{PRIMARY}"/>
        <rect x="100" y="140" width="86" height="70" rx="6" fill="{DEEP}"/>
        <rect x="198" y="140" width="86" height="70" rx="6" fill="{DEEP}"/>
        <rect x="100" y="222" width="184" height="12" rx="6" fill="{LIGHT}"/>
        <rect x="100" y="246" width="140" height="12" rx="6" fill="{LIGHT}"/>
        <path d="M262 84h44a10 10 0 0 1 10 10v22a14 14 0 0 0-28 0-14 14 0 0 0-28 0V94a10 10 0 0 1 2-10z" fill="{LIGHT}"/>
        <path d="M276 96h14l-4 20h-6z" fill="{DEEP}"/>
    """,
    "manhua": """
        <path d="M96 120h208a16 16 0 0 1 16 16v132a16 16 0 0 1-16 16H96a16 16 0 0 1-16-16V136a16 16 0 0 1 16-16z" fill="{PRIMARY}"/>
        <path d="M80 284c40 18 200 18 240 0v14a14 14 0 0 1-14 14H94a14 14 0 0 1-14-14z" fill="{LIGHT}"/>
        <path d="M148 232c22-8 34-26 40-46 8 22 24 40 48 46-18 10-26 26-28 46-8-20-26-36-48-42z" fill="{LIGHT}"/>
        <circle cx="200" cy="150" r="14" fill="{DEEP}"/>
        <path d="M120 152h40M240 152h40" stroke="{DEEP}" stroke-width="8" stroke-linecap="round"/>
        <path d="M110 176c14-12 30-16 44-12M290 176c-14-12-30-16-44-12" stroke="{LIGHT}" stroke-width="7" fill="none" stroke-linecap="round"/>
    """,
    "manhwa": """
        <circle cx="200" cy="196" r="86" fill="{PRIMARY}"/>
        <g stroke="{LIGHT}" stroke-width="9" stroke-linecap="round">
          <path d="M200 66v30M200 296v30M70 196h30M300 196h30"/>
          <path d="M108 104l22 22M292 288l-22-22M292 104l-22 22M108 288l22-22"/>
        </g>
        <path d="M170 178h60v16h-60z" fill="{DEEP}"/>
        <path d="M182 168h36v36h-36z" fill="{DEEP}"/>
        <path d="M164 214c22 18 50 18 72 0" stroke="{DEEP}" stroke-width="9" fill="none" stroke-linecap="round"/>
        <path d="M138 100l10 22 24 4-18 16 4 24-22-12-22 12 4-24-18-16 24-4z" fill="{WHITE}"/>
    """,
    "comics": """
        <rect x="72" y="104" width="256" height="200" rx="14" fill="{PRIMARY}"/>
        <rect x="94" y="126" width="102" height="76" rx="8" fill="{DEEP}"/>
        <rect x="208" y="126" width="98" height="76" rx="8" fill="{DEEP}"/>
        <rect x="94" y="214" width="212" height="14" rx="7" fill="{LIGHT}"/>
        <rect x="94" y="240" width="150" height="14" rx="7" fill="{LIGHT}"/>
        <rect x="94" y="266" width="180" height="14" rx="7" fill="{LIGHT}"/>
        <g fill="{LIGHT}">
          <circle cx="112" cy="146" r="4"/><circle cx="128" cy="146" r="4"/><circle cx="144" cy="146" r="4"/>
          <circle cx="160" cy="164" r="4"/><circle cx="176" cy="164" r="4"/><circle cx="192" cy="164" r="4"/>
        </g>
        <path d="M300 232l34 20-34 20z" fill="{LIGHT}"/>
    """,
    "gaming": """
        <path d="M118 148h164a54 54 0 0 1 54 54v20a54 54 0 0 1-54 54 54 54 0 0 1-46-26l-16-26h-40l-16 26a54 54 0 0 1-46 26 54 54 0 0 1-54-54v-20a54 54 0 0 1 54-54z" fill="{PRIMARY}"/>
        <path d="M108 176h30v14h-14v14h-16z" fill="{DEEP}"/>
        <circle cx="258" cy="188" r="13" fill="{DEEP}"/>
        <circle cx="288" cy="164" r="13" fill="{DEEP}"/>
        <rect x="150" y="182" width="100" height="12" rx="6" fill="{LIGHT}"/>
        <rect x="194" y="138" width="12" height="100" rx="6" fill="{LIGHT}"/>
    """,
    "e-sports": """
        <path d="M160 96h80v18h22a26 26 0 0 1 26 26v20a26 26 0 0 1-26 26h-16l-30 44h-58l-30-44h-16a26 26 0 0 1-26-26v-20a26 26 0 0 1 26-26h22z" fill="{PRIMARY}"/>
        <path d="M200 132c22 0 38 12 44 30-8-6-18-10-30-10-8 0-14 4-14 10s8 8 20 12c16 5 26 12 26 24 0 16-14 26-34 26-16 0-30-6-38-18 10 6 22 10 34 10 8 0 12-4 12-10s-6-8-18-12c-18-6-28-12-28-26 0-16 14-26 32-26z" fill="{DEEP}"/>
        <g stroke="{LIGHT}" stroke-width="8" stroke-linecap="round">
          <path d="M84 108v-24M64 96h40M316 108V84M296 96h40"/>
        </g>
        <rect x="96" y="272" width="208" height="12" rx="6" fill="{LIGHT}"/>
    """,
    "music": """
        <path d="M110 208a44 44 0 0 1 88 0v56a34 34 0 0 1-68 0z" fill="{PRIMARY}"/>
        <path d="M290 208a44 44 0 0 0-88 0v56a34 34 0 0 0 68 0z" fill="{PRIMARY}"/>
        <rect x="186" y="112" width="28" height="164" rx="14" fill="{PRIMARY}"/>
        <path d="M96 208a104 104 0 0 1 208 0" stroke="{LIGHT}" stroke-width="18" fill="none" stroke-linecap="round"/>
        <g stroke="{LIGHT}" stroke-width="9" stroke-linecap="round">
          <path d="M76 288v-24M104 296v-40M132 288v-24M160 300v-52M188 288v-24M216 296v-40M244 288v-24M272 300v-52M300 288v-24"/>
        </g>
    """,
    "movies": """
        <rect x="66" y="176" width="268" height="132" rx="12" fill="{PRIMARY}"/>
        <path d="M66 224h268M160 176v132M240 176v132" stroke="{DEEP}" stroke-width="10"/>
        <path d="M72 168l236-46 8 40-236 46z" fill="{LIGHT}"/>
        <path d="M124 152l20 24M176 136l20 24M228 120l20 24" stroke="{DEEP}" stroke-width="9"/>
        <path d="M296 96l58 0-58 96z" fill="{LIGHT}"/>
        <path d="M66 308h268l-40 34H106z" fill="{DEEP}"/>
    """,
    "books": """
        <rect x="112" y="240" width="196" height="40" rx="6" fill="{DEEP}"/>
        <rect x="120" y="252" width="196" height="40" rx="6" fill="{PRIMARY}"/>
        <rect x="112" y="264" width="196" height="40" rx="6" fill="{LIGHT}"/>
        <path d="M132 116c0-10 8-18 18-18h124c10 0 18 8 18 18v130H132z" fill="{PRIMARY}"/>
        <path d="M168 116c0-10 8-18 18-18h124v148H168z" fill="{LIGHT}"/>
        <path d="M228 98h26v96l-13-16-13 16z" fill="{PRIMARY}"/>
        <path d="M150 138h20M150 164h20" stroke="{DEEP}" stroke-width="8" stroke-linecap="round"/>
    """,
}


def artwork(key: str) -> str:
    """A motif on the shared circular backdrop."""
    return svg(
        f"""
        <defs>
          <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="{TINT}"/>
            <stop offset="100%" stop-color="{DEEP}"/>
          </linearGradient>
        </defs>
        <circle cx="200" cy="200" r="196" fill="url(#bg)"/>
        <circle cx="200" cy="200" r="192" fill="none" stroke="{PRIMARY}"
                stroke-width="4" stroke-opacity="0.35"/>
        {MOTIFS[key]}
        """
    )


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)

    for key in MOTIFS:
        path = os.path.join(OUT_DIR, f"{key}.svg")
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(artwork(key))
        print(f"  wrote {path}")

    print(f"\n{len(MOTIFS)} category illustrations written to {OUT_DIR}/")


if __name__ == "__main__":
    main()
