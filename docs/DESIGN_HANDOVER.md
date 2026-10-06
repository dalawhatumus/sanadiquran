# Sanadi: design handover for a new Claude Design chat

Paste everything below the line as the first message of the new chat, and attach the files listed in "Attach these files".

---

Hi! You're continuing the UI/UX design of **Sanadi (سَنَدي)**, a free Android app (sadaqah jariyah) that connects **elderly Muslims memorising the Quran** with **volunteer teachers of the same gender** over live audio calls. A previous chat already built the design system and many screens. That work is attached, and this message summarises every decision made so far. Please **continue in the same style, exactly matching the attached design system**. Don't restart or restyle anything.

## Attached files (read in this order)
1. `CLAUDE_DESIGN_BRIEF.md`: the full brief. It covers the audience, the non-negotiable accessibility rules, the icon metaphors and **Section 6, which lists every screen to design**.
2. `SPEC.md`: product spec (screens, call flow, optional notes, data model).
3. `Sanadi_Design_System.html`: the approved Phase 1 design system (tokens, type, components, icons; section 1h holds the masculine Arabic strings).
4. `Sanadi_Phase_2_standalone.html`: all screens designed so far (batch 1 and batch 2).
5. Brand files:
   - `sanadi-brand-sheet.png` and the logo SVGs
   - the cream logo SVGs: `sanadi-horizontal-cream`, `sanadi-vertical-cream`, `sanadi-mark-cream`, `sanadi-wordmark-cream`
   - `language.svg`: the outlined "ع / A" icon
6. `UthmanicHafs1Ver18.ttf`: the official KFGQPC Quran font. The licence forbids modifying it: no subsetting or conversion.

Everything is also in the GitHub repo `dalawhatumus/sanadiquran` (main branch), under `docs/` and `assets/`.

## Decisions already made (keep all of these)
- **Colours:**
  - Sanadi Green `#026C3B`, Deep Green `#0D4A3C`, Slate `#1E3A40`
  - Sage Dark `#4F6F60` for muted text; Sage `#8FAE9E` for decoration only, never text
  - Sage Tint `#DDE8E1`, Cream `#F4F0E8`, Warning `#A04A0A` (never bright red), Gold `#B88A2E` for decoration only
  - **The dark-mode palette in the design system is approved.**
- **Fonts:**
  - Tajawal (Arabic UI) and Montserrat (English UI), Medium 500 and Bold 700 only
  - **KFGQPC HAFS for Quran text only**
  - **Noto Naskh Arabic for athkar/dhikr text.** Quranic passages inside athkar (Ayat al-Kursi, al-Ikhlas, al-Falaq, an-Nas) stay in KFGQPC, marked subtly as Quran.
- **Text and touch targets:** body ≥ 18sp; layouts must work at **200% system text**. Bottom-tab labels and the "Settings" avatar label are capped at 130% (approved). Touch targets ≥ 56dp, primary buttons about 64dp.
- **Navigation:**
  - Student tabs: **Home · Quran · Athkar · Messages**
  - Teacher tabs: **Home · Students · Quran · Messages** (athkar reached from Quran)
  - Settings sit behind the profile avatar
- **Icons:**
  - filled, rounded and always labelled
  - custom icons: Quran-on-rehal (Quran tab, "Open in Quran"), misbaha (Athkar tab, Tasbeeh), prayer mat, moon over pillow, faceless students figures, "ع / A"
  - the grade "Good" uses a **tick in a circle**, never a thumbs-up
- **Logo:** use only the official SVGs; never retype or recolour the logo. The splash uses `sanadi-vertical-cream`.
- **Arabic copy is gender-aware.**
  - Design Arabic screens for a **female** user, e.g. سمِّعي الآن, افتحي, معلّمتي, أنا متاحة.
  - List the **masculine** version of every changed string in section 1h.
- **Teacher notes are OPTIONAL.** Teachers give feedback live on the call.
  - After a call the teacher sees **"Call ended"**: Done is the main button, with "Add notes for {name} (optional)" underneath.
  - No reminders, badges or "pending reports" anywhere.
  - The student's end-call dialog reads "Your session will be saved to your progress."
- **"My progress"** is reached from a compact card on student home, below "My teacher".
- **Quran text in the app always comes from the verified Tanzil/QUL data.** Sample text in designs is for layout only. **Never cut Quran text mid-word.**

## Fixes still to apply to the existing screens
1. **Embed the KFGQPC font in the standalone export.** Without it, Quran text renders broken when the file is opened elsewhere.
2. **Notes form (34):** "Save notes" is **enabled from the start**, because the pre-filled portion counts. Remove the "Fill in anything above to save" hint and the greyed-out state.
3. **25 Teacher's notes:** the "Your next portion" card must say **Al-Mulk 11–20**, matching the notification.
4. **"Ayahs to practise":** show the full ayah. Ayah 3 currently ends in "…ط", cut mid-word.
5. **Athkar menu at 200%:** let rows grow and wrap. The chevron currently runs into "Morning", and "After salah" is clipped.
6. **Prayer-mat icon:** make the mihrab arch bolder and add a short fringe at the bottom. It currently reads like a phone or ID card at small sizes.
7. **Dhikr text:** switch to Noto Naskh Arabic, keeping KFGQPC only for Quranic passages.
8. **Mushaf (39): two modes**, with a clear "Large text | Mushaf page" switch at the top; the app remembers the choice.
   - **Large text** is the default, like the current design, plus visible **page dividers ("Page 562")**.
   - **Mushaf page** is the exact 15-line Madani page, shown in portrait and **landscape**.

## Screens already done (don't redo, apart from the fixes above)
- **Batch 1:** 17 Student home, 19 Connecting, 21 In call (+ 23 end-call confirmation), 30 Teacher home, 31 Incoming call (+ lock screen)
- **Batch 2:** 34 Call ended + optional notes, 24 Call ended (student), 25 Teacher's notes, 26 My progress, 45 Athkar menu, 46 Dhikr counter, 47 Set complete, 39 Mushaf page

## What to do next (Section 6 of the brief)
Apply the 8 fixes above first, then design the remaining screens, each in **English, Arabic (female) and dark mode, with its states**, at 360×800:
- **Onboarding 1–16:** splash, language, welcome/sign-in, role, gender, name, permission explainers, permission denied, welcome tour, and the teacher application (10–16)
- **Student:** 18 session-type sheet, 20 no teacher available, 22 in call with mushaf open, 27 session history, 28 session detail, 29 my teachers
- **Teacher:** 32 in call (teacher), 33 missed call, 35 my students, 36 student detail
- **Shared:** 37 surah index, 38 juz index, 40 ayah menu, 41 audio player bar, 42 choose reciter, 43 mushaf download, 44 bookmarks, 48 messages list, 49 chat, 50 report/block
- **Settings 51–64**, **Admin 65–69**, **System states and notifications 70–75**

Work in batches of about 8–10 screens. After each batch, send a **standalone HTML export with all fonts and icons embedded** for review.
