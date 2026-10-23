# Flash application icon

Approved 2026-10-23: white continuous-corner tile, emerald-to-jade-to-mint
logo. The two bars and dot retain the geometry of FlClash's
`assets_source/images/icon/glyph.svg`, credited under the repository GPL-3.0
license. The SVG master is `app-icon.svg`; it contains no generated raster edges.

Regenerate the committed macOS 16–1024 px catalog and 550 px About-page asset:

```sh
uv run --with cairosvg==2.8.2 --with pillow==13.0.0 python tool/flash/generate_icon.py
```

CairoSVG needs the system Cairo library. With Homebrew on Apple Silicon, prefix
the command with `DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib` if the loader
cannot find `libcairo.2.dylib`. Rendering uses 4× supersampling and Lanczos
resampling. Release CI consumes the committed PNGs; it needs no Cairo install.

The status-bar icon is a separate native renderer whose colors describe proxy
configuration and IP quality; the application icon does not change with state.
