#!/usr/bin/env python3
"""Dérive les masters iOS 18 (Dark / Tinted) depuis assets/icons/app_icon.png.

Dark : fond doré → transparent (logo sur fond laissé au système).
Tinted : conversion luminance (niveaux de gris), opaque.

Relancer ensuite : dart run flutter_launcher_icons
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    src = root / "assets" / "icons" / "app_icon.png"
    out_dir = root / "assets" / "icons"
    if not src.is_file():
        raise SystemExit(f"Missing source icon: {src}")

    im = Image.open(src).convert("RGBA")
    w, h = im.size
    dark_pixels: list[tuple[int, int, int, int]] = []
    tinted_pixels: list[tuple[int, int, int, int]] = []

    for y in range(h):
        for x in range(w):
            r, g, b, a = im.getpixel((x, y))
            s = r + g + b
            lum = s // 3
            is_gold_bg = (lum > 36 and s > 105) or (lum > 32 and r > b + 20 and r > 55)
            if is_gold_bg:
                dark_pixels.append((0, 0, 0, 0))
            else:
                dark_pixels.append((r, g, b, 255))
            gray = int(0.299 * r + 0.587 * g + 0.114 * b)
            tinted_pixels.append((gray, gray, gray, 255))

    dark = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dark.putdata(dark_pixels)
    tinted = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    tinted.putdata(tinted_pixels)

    out_dir.mkdir(parents=True, exist_ok=True)
    dark_path = out_dir / "app_icon_ios_dark.png"
    tinted_path = out_dir / "app_icon_ios_tinted.png"
    dark.save(dark_path, optimize=True)
    tinted.save(tinted_path, optimize=True)
    print(f"Wrote {dark_path}")
    print(f"Wrote {tinted_path}")


if __name__ == "__main__":
    main()
