"""Generates the profile pictures in assets/avatars.

Faceless head-and-shoulders figures (the design rules ask for no faces),
four sets: male students (ms), female students (fs), male teachers (mt),
female teachers (ft). Run: python3 tools/brand/avatars.py
"""
import os

OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'avatars')
SKIN = ['#F1D3B5', '#D9A57A', '#B07B52', '#8A5A3B']
BG = {'green': '#026C3B', 'deep': '#0D4A3C', 'sage': '#8FAE9E', 'gold': '#B88A2E', 'slate': '#1E3A40', 'tint': '#DDE8E1', 'cream': '#F4F0E8', 'clay': '#A04A0A'}


def svg(body, bg):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
            f'<clipPath id="c"><circle cx="50" cy="50" r="50"/></clipPath>'
            f'<g clip-path="url(#c)"><rect width="100" height="100" fill="{bg}"/>{body}</g></svg>')


def shoulders(color, collar=None, trim=None):
    s = f'<path d="M14 104 C14 80 30 70 50 70 C70 70 86 80 86 104 Z" fill="{color}"/>'
    if trim:   # bisht (cloak) edges
        s += f'<path d="M40 71 L46 104 M60 71 L54 104" stroke="{trim}" stroke-width="3.5" fill="none"/>'
    if collar:
        s += f'<path d="M42 71 L50 80 L58 71" stroke="{collar}" stroke-width="2.5" fill="none" stroke-linejoin="round"/>'
    return s


def head(skin):
    return f'<rect x="44" y="56" width="12" height="16" rx="5" fill="{skin}"/><ellipse cx="50" cy="45" rx="15" ry="17" fill="{skin}"/>'


def beard(color, long=False):
    d = 'M35 44 C35 62 42 70 50 70 C58 70 65 62 65 44 C61 54 57 57 50 57 C43 57 39 54 35 44 Z'
    if long:
        d = 'M35 44 C35 66 42 78 50 78 C58 78 65 66 65 44 C61 55 57 58 50 58 C43 58 39 55 35 44 Z'
    return f'<path d="{d}" fill="{color}"/>'


def kufi(color, pattern=None):
    s = f'<path d="M34.5 40 C34.5 28 41 24 50 24 C59 24 65.5 28 65.5 40 Z" fill="{color}"/>'
    if pattern:
        s += f'<path d="M36 35 H64 M37.5 30 H62.5" stroke="{pattern}" stroke-width="1.6"/>'
    return s


def hair(color):
    return f'<path d="M34 44 C32 28 41 25 50 25 C60 25 68 28 66 44 C64 36 58 33 50 33 C42 33 36 36 34 44 Z" fill="{color}"/>'


def ghutra(color, agal='#1A1A1A', check=None):
    s = (f'<path d="M50 23 C36 23 31 33 31 46 C31 58 27 70 20 82 L80 82 C73 70 69 58 69 46 C69 33 64 23 50 23 Z" fill="{color}"/>')
    if check:
        s += (f'<path d="M50 23 C36 23 31 33 31 46 C31 58 27 70 20 82 L80 82 C73 70 69 58 69 46 C69 33 64 23 50 23 Z" '
              f'fill="none" stroke="{check}" stroke-width="1.4" stroke-dasharray="2 3"/>')
    return s


def ghutra_face(skin):
    return f'<ellipse cx="50" cy="48" rx="12.5" ry="15" fill="{skin}"/>'


def agal(color='#1A1A1A'):
    return f'<path d="M34 33 C40 29 60 29 66 33" stroke="{color}" stroke-width="3.2" fill="none" stroke-linecap="round"/>'


def turban(color, tail=True):
    s = (f'<path d="M32 40 C30 26 40 19 50 19 C60 19 70 26 68 40 C62 35 38 35 32 40 Z" fill="{color}"/>'
         f'<path d="M34 33 C42 28 58 28 66 33 M33 37 C42 32 58 32 67 37" stroke="#000" stroke-opacity="0.15" stroke-width="1.5" fill="none"/>')
    if tail:
        s += f'<path d="M64 36 C70 46 70 58 66 70 L60 70 C64 58 64 48 60 40 Z" fill="{color}"/>'
    return s


def hijab(color, edge=None):
    s = (f'<path d="M50 22 C34 22 30 36 31 50 C32 62 26 72 18 84 L82 84 C74 72 68 62 69 50 C70 36 66 22 50 22 Z" fill="{color}"/>')
    if edge:
        s += f'<path d="M37 48 C37 34 43 31 50 31 C57 31 63 34 63 48" stroke="{edge}" stroke-width="2.4" fill="none"/>'
    return s


def hijab_face(skin):
    return f'<ellipse cx="50" cy="48" rx="11.5" ry="14" fill="{skin}"/>'


def book(cover, pages='#FFFFFF'):
    return (f'<path d="M30 86 L50 82 L70 86 L70 104 L30 104 Z" fill="{cover}"/>'
            f'<path d="M33 87 L50 84 L67 87 L67 104 L33 104 Z" fill="{pages}"/>'
            f'<path d="M50 84 L50 104" stroke="{cover}" stroke-width="2"/>')


def glasses():
    return ('<circle cx="44" cy="46" r="4.6" fill="none" stroke="#2B2B2B" stroke-width="1.6"/>'
            '<circle cx="56" cy="46" r="4.6" fill="none" stroke="#2B2B2B" stroke-width="1.6"/>'
            '<path d="M48.6 46 H51.4" stroke="#2B2B2B" stroke-width="1.6"/>')


W, CREAM = '#FFFFFF', '#F4F0E8'
sets = {
    # Male students: elderly-friendly, kufi or ghutra, some white beards.
    'ms': [
        (BG['green'], shoulders(W, '#D8D8D8') + head(SKIN[0]) + beard('#E9E9E9') + kufi(W, '#D6D6D6')),
        (BG['slate'], shoulders('#E8E1D3', '#C9BFAF') + head(SKIN[1]) + beard('#BDBDBD') + kufi('#0D4A3C')),
        (BG['gold'], shoulders(W) + ghutra('#FFFFFF', check='#C33A3A') + ghutra_face(SKIN[1]) + beard('#DADADA') + agal()),
        (BG['sage'], shoulders('#2F4A44') + head(SKIN[2]) + hair('#3A2A1E') + beard('#3A2A1E')),
        (BG['deep'], shoulders(W, '#D8D8D8') + head(SKIN[3]) + beard('#F2F2F2', long=True) + kufi('#B88A2E', '#8C6820')),
        (BG['tint'], shoulders('#5B6B66') + head(SKIN[0]) + hair('#BDBDBD') + glasses()),
    ],
    # Female students: hijab in several colours.
    'fs': [
        (BG['green'], shoulders('#E8E1D3') + hijab('#F4F0E8', '#D8CDB8') + hijab_face(SKIN[0])),
        (BG['slate'], shoulders('#0D4A3C') + hijab('#8FAE9E', '#6F8F7F') + hijab_face(SKIN[1])),
        (BG['gold'], shoulders('#1E3A40') + hijab('#1E3A40', '#2E5560') + hijab_face(SKIN[2])),
        (BG['sage'], shoulders('#A04A0A') + hijab('#C98A5B', '#A86E43') + hijab_face(SKIN[1])),
        (BG['deep'], shoulders('#B88A2E') + hijab('#DDE8E1', '#B9CABF') + hijab_face(SKIN[3])),
        (BG['tint'], shoulders('#4F6F60') + hijab('#0D4A3C', '#1F6B57') + hijab_face(SKIN[0]) + glasses()),
    ],
    # Male teachers: imamah, ghutra with bisht, open book.
    'mt': [
        (BG['green'], shoulders('#1A1A1A', trim='#B88A2E') + head(SKIN[0]) + beard('#3A2A1E', long=True) + turban(W) + book('#026C3B')),
        (BG['slate'], shoulders('#5A4632', trim='#D4AF5A') + ghutra('#FFFFFF') + ghutra_face(SKIN[1]) + beard('#2A2A2A') + agal() + book('#B88A2E')),
        (BG['gold'], shoulders(W, '#D8D8D8') + head(SKIN[2]) + beard('#1E1E1E', long=True) + turban('#0D4A3C') + book('#1E3A40')),
        (BG['sage'], shoulders('#1E3A40', trim='#B88A2E') + ghutra('#FFFFFF', check='#C33A3A') + ghutra_face(SKIN[0]) + beard('#9E9E9E') + agal() + book('#026C3B')),
        (BG['deep'], shoulders(W, '#D8D8D8') + head(SKIN[3]) + beard('#151515') + kufi(W, '#D6D6D6') + book('#B88A2E')),
        (BG['tint'], shoulders('#0D4A3C', trim='#B88A2E') + head(SKIN[1]) + beard('#E6E6E6', long=True) + turban('#F4F0E8') + book('#A04A0A')),
    ],
    # Female teachers: hijab with an open book.
    'ft': [
        (BG['green'], shoulders('#1E3A40') + hijab('#1E3A40', '#2E5560') + hijab_face(SKIN[0]) + book('#B88A2E')),
        (BG['slate'], shoulders('#E8E1D3') + hijab('#F4F0E8', '#D8CDB8') + hijab_face(SKIN[1]) + book('#026C3B')),
        (BG['gold'], shoulders('#0D4A3C') + hijab('#0D4A3C', '#1F6B57') + hijab_face(SKIN[2]) + book('#F4F0E8', '#FFFFFF')),
        (BG['sage'], shoulders('#5A4632') + hijab('#2B2B2B', '#444') + hijab_face(SKIN[1]) + book('#026C3B')),
        (BG['deep'], shoulders('#8FAE9E') + hijab('#DDE8E1', '#B9CABF') + hijab_face(SKIN[3]) + book('#B88A2E')),
        (BG['tint'], shoulders('#A04A0A') + hijab('#C98A5B', '#A86E43') + hijab_face(SKIN[0]) + glasses() + book('#1E3A40')),
    ],
}

os.makedirs(OUT, exist_ok=True)
for prefix, items in sets.items():
    for i, (bg, body) in enumerate(items, start=1):
        with open(os.path.join(OUT, f'{prefix}{i}.svg'), 'w') as f:
            f.write(svg(body, bg))
print('wrote', sum(len(v) for v in sets.values()), 'avatars')
