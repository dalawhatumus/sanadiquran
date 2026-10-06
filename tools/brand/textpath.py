"""Shape text with HarfBuzz and return SVG path data (font units -> px)."""
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.varLib.instancer import instantiateVariableFont

_cache = {}


def _load(path, wght=None):
    key = (path, wght)
    if key not in _cache:
        tt = TTFont(path)
        if wght is not None and 'fvar' in tt:
            tt = instantiateVariableFont(tt, {'wght': wght})
            import io
            buf = io.BytesIO(); tt.save(buf); data = buf.getvalue()
            tt = TTFont(io.BytesIO(data))
        else:
            data = open(path, 'rb').read()
        _cache[key] = (tt, data)
    return _cache[key]


def text_path(text, path, size, x=0.0, y=0.0, wght=None, tracking=0.0, rtl=None):
    """Return (d, bbox) for text with baseline at y, starting at x.

    size: font size in px. tracking: extra px between glyphs.
    bbox: (xmin, ymin, xmax, ymax) in output px.
    """
    tt, data = _load(path, wght)
    face = hb.Face(data)
    font = hb.Font(face)
    upem = face.upem
    font.scale = (upem, upem)
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    if rtl is not None:
        buf.direction = 'rtl' if rtl else 'ltr'
    hb.shape(font, buf, {'kern': True, 'liga': True})
    gs = tt.getGlyphSet()
    names = tt.getGlyphOrder()
    s = size / upem
    pen = SVGPathPen(gs)
    bpen = BoundsPen(gs)
    cx = 0.0
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        name = names[info.codepoint]
        ox = x + (cx + pos.x_offset) * s
        oy = y - pos.y_offset * s
        t = (s, 0, 0, -s, ox, oy)
        gs[name].draw(TransformPen(pen, t))
        gs[name].draw(TransformPen(bpen, t))
        cx += pos.x_advance + tracking / s
    return pen.getCommands(), bpen.bounds
