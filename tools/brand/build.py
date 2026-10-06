"""Build the Sanadi logo set as SVG.

The mark is the owner-supplied artwork traced to vector by trace.py
(out/mark-path.txt). The wordmark is set in Tajawal Bold and Montserrat
Medium, converted to outlines.
"""
import os
from textpath import text_path

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'out')
os.makedirs(OUT, exist_ok=True)

TAJ_B = os.path.join(HERE, 'Tajawal-Bold.ttf')
MONT = os.path.join(HERE, 'Montserrat[wght].ttf')

GREEN = '#026C3B'      # sampled from the supplied mark
DEEP = '#0D4A3C'       # palette deep green
CREAM = '#F4F0E8'      # palette cream

_bbox, _path = open(os.path.join(OUT, 'mark-path.txt')).read().split('\n', 1)
MX0, MY0, MX1, MY1 = map(float, _bbox.split())
MARK_W, MARK_H = MX1 - MX0, MY1 - MY0
MARK_RATIO = MARK_W / MARK_H


def mark_group(x, y, height):
    """The traced mark scaled to `height`, with its top-left at (x, y)."""
    s = height / MARK_H
    return (f'<g transform="translate({x:.1f},{y:.1f}) scale({s:.5f}) '
            f'translate({-MX0:.1f},{-MY0:.1f})">'
            f'<path fill-rule="evenodd" d="{_path}"/></g>')


def wordmark_paths(x0=0.0, y0=0.0, scale=1.0):
    """Arabic name over spaced Latin name. Returns (paths, width, height),
    with the block's top-left at (x0, y0)."""
    ar_size, en_size = 300 * scale, 74 * scale
    track = 58 * scale
    _, ab = text_path('سَنَدي', TAJ_B, ar_size, 0, 0, rtl=True)
    _, eb = text_path('SANADI', MONT, en_size, 0, 0, wght=500, tracking=track)
    aw, ah = ab[2] - ab[0], ab[3] - ab[1]
    ew, eh = eb[2] - eb[0], eb[3] - eb[1]
    w = max(aw, ew)
    gap = 46 * scale
    ar, _ = text_path('سَنَدي', TAJ_B, ar_size,
                      x0 + (w - aw) / 2 - ab[0], y0 - ab[1], rtl=True)
    ey = y0 + ah + gap
    en, _ = text_path('SANADI', MONT, en_size,
                      x0 + (w - ew) / 2 - eb[0], ey - eb[1], wght=500,
                      tracking=track)
    return [ar, en], w, ah + gap + eh


def paths_xml(paths):
    return ''.join(f'<path d="{p}"/>' for p in paths)


def doc(w, h, inner, fill, bg=None):
    rect = f'<rect width="{w:.0f}" height="{h:.0f}" fill="{bg}"/>' if bg else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.0f} {h:.0f}">'
            f'{rect}<g fill="{fill}">{inner}</g></svg>')


def layouts(fill, bg=None):
    pad = 80
    out = {}
    mh = 700
    out['mark'] = doc(mh * MARK_RATIO + 2 * pad, mh + 2 * pad,
                      mark_group(pad, pad, mh), fill, bg)

    wp, ww, wh = wordmark_paths(pad, pad)
    out['wordmark'] = doc(ww + 2 * pad, wh + 2 * pad, paths_xml(wp), fill, bg)

    # horizontal lockups: mark as tall as the wordmark block
    mw = wh * MARK_RATIO
    gap = 90
    W, H = pad + mw + gap + ww + pad, wh + 2 * pad
    wp_l, _, _ = wordmark_paths(pad + mw + gap, pad)
    out['horizontal'] = doc(W, H, mark_group(pad, pad, wh) + paths_xml(wp_l),
                            fill, bg)
    wp_r, _, _ = wordmark_paths(pad, pad)
    out['horizontal-rtl'] = doc(W, H, paths_xml(wp_r) +
                                mark_group(pad + ww + gap, pad, wh), fill, bg)

    # vertical lockup: mark above the name, a little narrower than it
    vw_mark = ww * 0.62
    vh = vw_mark / MARK_RATIO
    VW = ww + 2 * pad
    vy = pad + vh + 70
    wp_v, _, _ = wordmark_paths(pad, vy)
    out['vertical'] = doc(VW, vy + wh + pad,
                          mark_group((VW - vw_mark) / 2, pad, vh)
                          + paths_xml(wp_v), fill, bg)
    return out


def app_icon(fg, bg, mark_w=252):
    """Android adaptive icon at 432px (108dp @4x). The mark stays inside the
    66dp safe zone (264px circle) so no launcher mask can crop it."""
    size = 432
    mh = mark_w / MARK_RATIO
    mark = mark_group((size - mark_w) / 2, (size - mh) / 2, mh)
    return (doc(size, size, mark, fg),            # foreground layer
            doc(size, size, '', fg, bg),          # background layer
            doc(size, size, mark, fg, bg))        # flattened preview


if __name__ == '__main__':
    variants = {
        'green': (GREEN, None),
        'deep': (DEEP, None),
        'cream': (CREAM, None),
        'black': ('#111111', None),
        'white': ('#FFFFFF', None),
        'green-on-cream': (GREEN, CREAM),
        'cream-on-green': (CREAM, GREEN),
        'cream-on-deep': (CREAM, DEEP),
    }
    for vname, (fill, bg) in variants.items():
        for lname, content in layouts(fill, bg).items():
            with open(os.path.join(OUT, f'sanadi-{lname}-{vname}.svg'), 'w') as f:
                f.write(content)
    for name, (fg, bg) in {'app-icon': (CREAM, GREEN),
                           'app-icon-light': (GREEN, CREAM)}.items():
        fore, back, full = app_icon(fg, bg)
        open(os.path.join(OUT, f'{name}.svg'), 'w').write(full)
        open(os.path.join(OUT, f'{name}-foreground.svg'), 'w').write(fore)
        open(os.path.join(OUT, f'{name}-background.svg'), 'w').write(back)
    # Play Store listing icon: 512px, full bleed
    ps, pw = 512, 380
    ph = pw / MARK_RATIO
    store = doc(ps, ps, mark_group((ps - pw) / 2, (ps - ph) / 2, ph), CREAM, GREEN)
    open(os.path.join(OUT, 'play-store-icon.svg'), 'w').write(store)
    print('built', len(os.listdir(OUT)), 'files')
