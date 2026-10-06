# Quran text

`hafs.json` holds the Quran text published by the King Fahd Glorious Quran
Printing Complex (KFGQPC), Hafs narration, version 18, built for the
`UthmanicHafs1Ver18.ttf` font. It was taken from the KFGQPC developer data
(mirrored at github.com/thetruetruth/quran-data-kfgqpc, `hafs/data/hafsData_v18.json`).

The ayah text is unmodified. The file is only repacked into a compact array:
`[sura, ayah, page, juz, line_start, line_end, text]`, plus a sura list
`[arabic name, english name, ayah count, first page, juz]`.

Checks done when packing: 6,236 ayahs, 114 suras, 604 pages.
