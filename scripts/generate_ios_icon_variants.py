#!/usr/bin/env python3
"""Dérive les masters iOS 18 (Dark / Tinted) depuis assets/icons/app_icon.png.

Dark : tout sauf le « V » et le filet quasi achromatiques → transparent, pour laisser
le fond au système (évite les restes de texture dorée sombre).

Tinted : conversion luminance (niveaux de gris), opaque.

Relancer ensuite : dart run flutter_launcher_icons
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image


def _chroma(r: int, g: int, b: int) -> int:
    return max(r, g, b) - min(r, g, b)


def _keep_opaque_for_dark_icon(r: int, g: int, b: int) -> bool:
    """True = pixel du logo / filet (on garde). False = fond → transparent."""
    s = r + g + b
    lum = s // 3
    ch = _chroma(r, g, b)
    # Noir du V + antialiasing neutre (faible chroma).
    if lum <= 52 and ch <= 22:
        return True
    # Très sombre même légèrement teinté (bord fin).
    if lum <= 18:
        return True
    # Reste : texture dorée (même sombre), ombres chaudes, etc. → transparent.
    return False


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
            if _keep_opaque_for_dark_icon(r, g, b):
                dark_pixels.append((r, g, b, 255))
            else:
                dark_pixels.append((0, 0, 0, 0))
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
