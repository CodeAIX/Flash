#!/usr/bin/env python3
"""Render the approved Flash SVG into application assets (CairoSVG 2.8.2)."""
from io import BytesIO
from pathlib import Path

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'flash/branding/app-icon.svg'


def main():
    directory = ROOT / 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
    outputs = [(directory / f'app_icon_{size}.png', size)
               for size in (16, 32, 64, 128, 256, 512, 1024)]
    outputs.append((ROOT / 'assets/images/icon.png', 550))
    for target, size in outputs:
        rendered = cairosvg.svg2png(url=str(SOURCE), output_width=size * 4,
                                   output_height=size * 4)
        with Image.open(BytesIO(rendered)) as image:
            image.resize((size, size), Image.Resampling.LANCZOS).save(target)
        print(target.relative_to(ROOT))


if __name__ == '__main__':
    main()
