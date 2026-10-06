# Brand asset generator

Rebuilds every logo variant, the app icon and the brand sheet in `assets/brand/` from code, so the logo stays crisp and can be regenerated after any tweak.

Needs: Python 3 with `uharfbuzz` and `fonttools`, Node with `playwright-core`, Chromium, and the Tajawal and Montserrat font files (from github.com/google/fonts, OFL licence) next to these scripts.

```sh
python3 build.py                        # writes SVGs to out/
node export.mjs ../../assets/brand      # PNGs, app icons, brand sheet
```
