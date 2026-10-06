"""Build the Sanadi logo set as SVG."""
import os
from textpath import text_path

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'out')
os.makedirs(OUT, exist_ok=True)

TAJ_XB = os.path.join(HERE, 'Tajawal-ExtraBold.ttf')
TAJ_B = os.path.join(HERE, 'Tajawal-Bold.ttf')
MONT = os.path.join(HERE, 'Montserrat[wght].ttf')

GREEN = '#0B6B3F'      # logo green
DEEP = '#0D4A3C'       # palette deep green
NIGHT = '#1E3A40'      # palette dark slate
SAGE = '#8FAE9E'       # palette sage
CREAM = '#F4F0E8'      # palette cream


def book_paths():
    """Open-book base of the mark, in a 1000x1000 box: two bold leaves per
    side sweeping up from the spine at (500, 900)."""
    def side(sign):
        x = lambda v: 500 + sign * (v - 500)
        outer = (f'M500,915 C{x(440)},825 {x(310)},735 {x(70)},700 '
                 f'C{x(120)},760 {x(220)},800 {x(300)},828 '
                 f'C{x(390)},858 {x(455)},880 500,915 Z')
        inner = (f'M500,840 C{x(455)},770 {x(375)},708 {x(205)},676 '
                 f'C{x(245)},726 {x(320)},748 {x(385)},775 '
                 f'C{x(440)},797 {x(478)},815 500,840 Z')
        return [outer, inner]
    return side(-1) + side(1)


def mark_paths():
    """Return path data for the mark (seen + fatha above an open book)."""
    size = 560
    d, b = text_path('سَ', TAJ_XB, size, 0, 0, rtl=True)
    w = b[2] - b[0]
    # centre the letter horizontally, sitting just above the book
    dx = 500 - (b[0] + w / 2)
    dy = 650 - b[3]
    letter, _ = text_path('سَ', TAJ_XB, size, dx, dy, rtl=True)
    return [letter] + book_paths()


def svg(view, paths, fill, bg=None):
    w, h = view
    body = ''.join(f'<path d="{p}"/>' for p in paths)
    rect = f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">'
            f'{rect}<g fill="{fill}">{body}</g></svg>')


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


def placed_mark(x, y, size):
    """Mark paths scaled into a size x size box at (x, y)."""
    s = size / 1000
    return (f'<g transform="translate({x:.1f},{y:.1f}) scale({s:.4f})">'
            + paths_xml(mark_paths()) + '</g>')


def paths_xml(paths):
    return ''.join(f'<path d="{p}"/>' for p in paths)


def doc(w, h, inner, fill, bg=None):
    rect = f'<rect width="{w:.0f}" height="{h:.0f}" fill="{bg}"/>' if bg else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.0f} {h:.0f}">'
            f'{rect}<g fill="{fill}">{inner}</g></svg>')


# The mark's artwork spans roughly x 70-930, y 150-915 of its 1000 box.
MARK_LEFT, MARK_RIGHT, MARK_TOP, MARK_BOTTOM = 70, 930, 150, 915


def layouts(fill, bg=None):
    pad = 80
    out = {'mark': doc(1000, 1000, placed_mark(0, 0, 1000), fill, bg)}

    wp, ww, wh = wordmark_paths(pad, pad)
    out['wordmark'] = doc(ww + 2 * pad, wh + 2 * pad, paths_xml(wp), fill, bg)

    # horizontal lockups: mark height matches the wordmark block
    msize = wh * 1000 / (MARK_BOTTOM - MARK_TOP)
    s = msize / 1000
    mtop = pad - MARK_TOP * s
    mw = (MARK_RIGHT - MARK_LEFT) * s
    gap = 80
    W, H = pad + mw + gap + ww + pad, wh + 2 * pad
    wp_l, _, _ = wordmark_paths(pad + mw + gap, pad)
    out['horizontal'] = doc(W, H, placed_mark(pad - MARK_LEFT * s, mtop, msize)
                            + paths_xml(wp_l), fill, bg)
    wp_r, _, _ = wordmark_paths(pad, pad)
    out['horizontal-rtl'] = doc(W, H, paths_xml(wp_r) + placed_mark(
        pad + ww + gap - MARK_LEFT * s, mtop, msize), fill, bg)

    # vertical lockup: mark above wordmark
    vm = 470
    vs = vm / 1000
    VW = max(ww, (MARK_RIGHT - MARK_LEFT) * vs) + 2 * pad
    vy = pad + (MARK_BOTTOM - MARK_TOP) * vs + 60
    wp_v, _, _ = wordmark_paths((VW - ww) / 2, vy)
    out['vertical'] = doc(VW, vy + wh + pad, placed_mark(
        (VW - vm) / 2, pad - MARK_TOP * vs, vm) + paths_xml(wp_v), fill, bg)
    return out


def app_icon(fg, bg):
    """Android adaptive icon at 432px (108dp @4x). The mark stays inside the
    66dp safe zone (264px circle) so no launcher mask can crop it."""
    size, msize = 432, 280
    off = (size - msize) / 2
    y = off - 6  # the artwork's visual centre sits low in its box
    mark = placed_mark(off, y, msize)
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
    # Play Store listing icon: 512px, full bleed, mark at ~72% width
    ps = 512; pm = 430
    store = doc(ps, ps, placed_mark((ps - pm) / 2, (ps - pm) / 2 - 14, pm), CREAM, GREEN)
    open(os.path.join(OUT, 'play-store-icon.svg'), 'w').write(store)
    print('built', len(os.listdir(OUT)), 'files')
