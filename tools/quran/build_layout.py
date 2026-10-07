"""Builds assets/quran/layout.json: the Madani 15-line page layout of the
1441 AH King Fahd Complex mushaf, the printing the KFGQPC Hafs v18 font and
text follow.

Line breaks come from the quran-qcf4 package (pages/*.json, MIT licence).
The words themselves are the KFGQPC Hafs v18 text from hafs.json, so the
app renders only the verified KFGQPC text. Words are matched by position;
where the two sources split a word differently, by relative position in
the ayah. Every ayah's first and last line is then checked against
KFGQPC's own page/line numbers.

Usage: build_layout.py <quran-qcf4/pages> <hafs.json> <layout.json>

Output: {"pages": [[line, ...] x 604]}, a line being
  ["h", sura] | ["b"] | ["t", [[s, a, i0, i1], ...]]
where i0..i1 are KFGQPC word numbers (1-based) and i1 == n+1 means the
ayah-number marker ends the line.
"""
import json
import re
import sys
import unicodedata
from collections import defaultdict

pages_dir, hafs_path, out_path = sys.argv[1:4]
ARABIC = re.compile('[ء-يٱ]')


def letters(w):
    return max(1, sum(1 for c in w if ARABIC.match(c) and unicodedata.category(c) == 'Lo'))


# KFGQPC words per ayah, and KFGQPC's page/line data.
h = json.load(open(hafs_path))
kw, kline = {}, {}
for s, a, p, j, ls, le, t in h['ayahs']:
    toks = t.replace(' ', ' ').split(' ')
    merged = []
    for tok in toks[:-1]:                      # last token is the number
        if merged and not ARABIC.search(merged[-1]):
            merged[-1] += ' ' + tok            # e.g. "۞ إِنَّ"
        else:
            merged.append(tok)
    kw[(s, a)] = merged
    kline[(s, a)] = (p, ls, le)

# The 1441 layout: each page's lines and each ayah's words with their line.
raw_pages = []
lay = defaultdict(list)                        # (s,a) -> [(text, (pg, li))]
for pg in range(1, 605):
    d = json.load(open(f'{pages_dir}/{pg:03d}.json'))
    lines = sorted(d['lines'], key=lambda l: l['line'])
    raw_pages.append(lines)
    for li, ln in enumerate(lines):
        for w in ln['words']:
            if w['type'] == 'word' and ARABIC.search(w['text']):
                s, a = map(int, w['verse_key'].split(':'))
                lay[(s, a)].append((w['text'], (pg, li)))

# Place every KFGQPC word on a line.
place, by_share = {}, 0
for k, toks in kw.items():
    lw = lay[k]
    if len(lw) == len(toks):
        for i, (_, pos) in enumerate(lw):
            place[(k[0], k[1], i + 1)] = pos
        continue
    by_share += 1
    ks = [letters(t) for t in toks]
    ls_ = [letters(w) for w, _ in lw]
    tk, tl = sum(ks), sum(ls_)
    acc = 0
    for i, n in enumerate(ks):
        mid = (acc + n / 2) / tk
        cum, j = 0, 0
        for j, m in enumerate(ls_):
            if (cum + m) / tl >= mid:
                break
            cum += m
        place[(k[0], k[1], i + 1)] = lw[j][1]
        acc += n

pages = []
for lines in raw_pages:
    out = []
    for ln in lines:
        types = {w['type'] for w in ln['words']}
        if 'surah_header' in types:
            out.append(['h', ln['words'][0]['sura']])
        elif 'bismillah' in types:
            out.append(['b'])
        else:
            out.append(['t', []])
    pages.append(out)

mismatch = []
for (s, a) in sorted(kw):
    n = len(kw[(s, a)])
    first = last = None
    for i in range(1, n + 1):
        pg, li = place[(s, a, i)]
        assert last is None or (pg, li) >= last, ('order', s, a, i)
        first = first or (pg, li)
        last = (pg, li)
        line = pages[pg - 1][li]
        assert line[0] == 't', (s, a, pg, li)
        segs = line[1]
        end = i + 1 if i == n else i
        if segs and segs[-1][0] == s and segs[-1][1] == a:
            segs[-1][3] = end
        else:
            segs.append([s, a, i, end])
    p, ls, le = kline[(s, a)]
    if first != (p, ls - 1) or (last[0] == p and last[1] != le - 1):
        mismatch.append((s, a, 'kfgqpc', (p, ls, le), 'layout', (first[0], first[1] + 1, last[1] + 1)))

for pg, lines in enumerate(pages, start=1):
    for li, ln in enumerate(lines):
        if ln[0] == 't':
            assert ln[1], ('empty line', pg, li + 1)

print('ayahs whose lines differ from KFGQPC line data:', len(mismatch))
for m in mismatch[:15]:
    print('  ', m)
json.dump({'source': 'Madani 15-line layout, 1441 AH printing. Line breaks: quran-qcf4 (MIT). Words: KFGQPC Hafs v18.',
           'pages': pages}, open(out_path, 'w'), separators=(',', ':'))
print('ok: all 6236 ayahs placed;', by_share, 'ayahs matched by relative position')
