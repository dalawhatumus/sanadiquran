# Quran text and page layout

## `hafs.json`: the text
The Quran text published by the King Fahd Glorious Quran Printing Complex
(KFGQPC), Hafs narration, version 18, made for the `UthmanicHafs1Ver18.ttf`
font. Taken from the KFGQPC developer data (mirrored at
github.com/thetruetruth/quran-data-kfgqpc, `hafs/data/hafsData_v18.json`).

The ayah text is unmodified, only repacked as
`[sura, ayah, page, juz, line_start, line_end, text]`, plus a sura list
`[arabic name, english name, ayah count, first page, juz]`.

## `layout.json`: the 15-line Madani pages
Which words sit on which line of which page, for the 1441 AH King Fahd
Complex printing (the one the KFGQPC Hafs v18 font follows). The line breaks
come from the `quran-qcf4` package (MIT licence, see
`tools/quran/LICENSE-quran-qcf4.md`); the words shown are always the KFGQPC
text above. Rebuild with `tools/quran/build_layout.py`.

## Checks
- 6,236 ayahs, 114 surahs, 604 pages.
- Every ayah starts and ends on exactly the page and line given by KFGQPC's
  own data (0 differences).
- `test/quran_data_test.dart` checks on every build that each word of every
  ayah appears exactly once, in order, and that surah headers sit where
  surahs begin.
