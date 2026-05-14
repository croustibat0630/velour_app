#!/usr/bin/env python3
"""Inset Velour marketing icons (~14 % smaller) for iOS squircle / Android adaptive safe zone.

Reads the masters used by flutter_launcher_icons (`app_icon`, `app_icon_ios_tinted`),
Run from repo root: python3 scripts/pad_velour_app_icons.py
Then: dart run flutter_launcher_icons

Do not run twice in a row without restoring assets/icons/*.png from git, or the
motif will shrink again.

iOS 18 « icônes sombres » : le slot *Dark* doit reprendre le même visuel lisible que
`app_icon.png` (or + V). Ne pas regénérer depuis l’ancien master noir ; on copie
le résultat du pad vers `app_icon_ios_dark.png` après coup.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

from PIL import Image

# ~7 % empty margin on each side of the 1024 master (stronger than a tiny shrink).
SCALE = 0.86
CANVAS = 1024

ROOT = Path(__file__).resolve().parent.parent
ICONS = ROOT / "assets" / "icons"
FILES = [
    ICONS / "app_icon.png",
    ICONS / "app_icon_ios_tinted.png",
]


def _corner_average_rgba(im: Image.Image) -> tuple[int, int, int, int]:
    w, h = im.size
    pts = ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))
    rs = gs = bs = als = 0
    for x, y in pts:
        p = im.getpixel((x, y))
        if not isinstance(p, tuple):
            p = (p, p, p, 255)
        if len(p) == 3:
            r, g, b = p
            a = 255
        else:
            r, g, b, a = p
        rs += r
        gs += g
        bs += b
        als += a
    n = len(pts)
    return (rs // n, gs // n, bs // n, als // n)


def pad_one(path: Path, *, transparent_canvas: bool) -> None:
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    if w != h:
        side = max(w, h)
        sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        sq.paste(im, ((side - w) // 2, (side - h) // 2))
        im = sq
    if im.size != (CANVAS, CANVAS):
        im = im.resize((CANVAS, CANVAS), Image.Resampling.LANCZOS)

    new_side = max(1, int(round(CANVAS * SCALE)))
    scaled = im.resize((new_side, new_side), Image.Resampling.LANCZOS)

    if transparent_canvas:
        canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    else:
        bg = _corner_average_rgba(im)
        canvas = Image.new("RGBA", (CANVAS, CANVAS), bg)

    ox = (CANVAS - new_side) // 2
    oy = (CANVAS - new_side) // 2
    canvas.paste(scaled, (ox, oy), scaled)
    canvas.save(path, format="PNG", optimize=True)
    print(f"OK {path.relative_to(ROOT)} -> inset scale={SCALE}")


def main() -> int:
    for p in FILES:
        if not p.is_file():
            print(f"Missing {p}", file=sys.stderr)
            return 1
    dark_out = ICONS / "app_icon_ios_dark.png"
    if not dark_out.is_file():
        print(f"Missing {dark_out}", file=sys.stderr)
        return 1
    pad_one(ICONS / "app_icon.png", transparent_canvas=False)
    shutil.copyfile(ICONS / "app_icon.png", dark_out)
    print(f"OK {dark_out.relative_to(ROOT)} <- app_icon.png (iOS 18 dark readability)")
    pad_one(ICONS / "app_icon_ios_tinted.png", transparent_canvas=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
