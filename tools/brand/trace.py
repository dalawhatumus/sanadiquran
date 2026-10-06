"""Trace the supplied mark PNG into a single SVG path (out/mark-traced.svg)."""
import sys
from collections import Counter
import numpy as np
import potrace
from PIL import Image, ImageFilter

src = sys.argv[1]
im = Image.open(src).convert('RGBA')
alpha = im.getchannel('A')

# Dominant opaque colour = brand green.
px = [p[:3] for p in im.getdata() if p[3] > 250]
green = Counter(px).most_common(1)[0][0]
print('green #%02X%02X%02X' % green)

# Upscale 2x with smoothing before tracing for cleaner curves.
scale = 2
big = alpha.resize((alpha.width * scale, alpha.height * scale), Image.LANCZOS)
big = big.filter(ImageFilter.GaussianBlur(1.2))
bitmap = potrace.Bitmap(np.array(big) > 128)
plist = bitmap.trace(turdsize=40, alphamax=1.0, opticurve=True, opttolerance=0.2)

parts = []
W, H = big.size
for curve in plist:
    pts = [curve.start_point] + [seg.end_point for seg in curve.segments]
    xs_, ys_ = [p.x for p in pts], [p.y for p in pts]
    if min(xs_) < 2 and min(ys_) < 2 and max(xs_) > W - 2 and max(ys_) > H - 2:
        continue  # potrace's frame around the whole bitmap
    s = curve.start_point
    d = [f'M{s.x / scale:.2f},{s.y / scale:.2f}']
    for seg in curve.segments:
        if seg.is_corner:
            d.append(f'L{seg.c.x / scale:.2f},{seg.c.y / scale:.2f}'
                     f'L{seg.end_point.x / scale:.2f},{seg.end_point.y / scale:.2f}')
        else:
            d.append(f'C{seg.c1.x / scale:.2f},{seg.c1.y / scale:.2f} '
                     f'{seg.c2.x / scale:.2f},{seg.c2.y / scale:.2f} '
                     f'{seg.end_point.x / scale:.2f},{seg.end_point.y / scale:.2f}')
    d.append('Z')
    parts.append(''.join(d))

path = ' '.join(parts)
ys, xs = np.nonzero(np.array(alpha) > 128)
bbox = (xs.min(), ys.min(), xs.max(), ys.max())
print('bbox', bbox, 'curves', len(plist))
open('out/mark-path.txt', 'w').write(f'{bbox[0]} {bbox[1]} {bbox[2]} {bbox[3]}\n{path}')
w, h = alpha.size
open('out/mark-traced.svg', 'w').write(
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">'
    f'<path fill="#%02X%02X%02X" fill-rule="evenodd" d="{path}"/></svg>' % green)
