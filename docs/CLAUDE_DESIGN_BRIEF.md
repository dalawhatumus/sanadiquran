# Sanadi: brief for Claude Design

Paste everything below the line into Claude Design and attach `assets/brand/sanadi-logo-trimmed.png`. Work through the phases in order: don't design screens until the design system in Phase 1 is approved.

---

## Project

**Sanadi (سَنَدي)** is a free Android app (sadaqah jariyah) that connects **elderly** Muslims memorising the Quran with **volunteer teachers of the same gender**. The student taps one big "Recite now" button, the app rings an available teacher, they recite on a live audio call, and the teacher logs a short report that builds the student's progress. The app also has a mushaf (Quran reader) and athkar (daily remembrances with a tap counter).

The main competitor, Waratel, is slow, cluttered, has small grey text and makes students browse long teacher lists. Sanadi must feel **calm, dignified, obvious and fast**.

## Audience

- **Students:** men and women aged 55–85, often low-confidence phone users, sometimes with weak eyesight or shaky hands. Arabic or English speakers in the Arab world and South Africa.
- **Teachers:** volunteer huffaz of any age who want minimal admin.

Design for a 70-year-old grandmother using a budget Android phone (360×800dp) at large system font size.

## Brand (from the attached logo)

- **Wordmark:** calligraphic **سَنَدي** in deep green with **gold fatha marks**, and "SANADI" in a spaced serif between two gold rules. Always show the Arabic name **with its vowel marks** (سَنَدي), so it isn't read as "Sindi".
- **Colours sampled from the logo:**
  - Deep green `#063C24` (darkest strokes)
  - Brand green `#0B4A2C` (primary)
  - Gold `#C49A3E` (accent, from the fatha strokes and rules)
  - Suggested supporting colours, to refine: warm off-white background `#FAF7F0`, near-black text `#1B1B1B`, light green tint for selected states, light gold tint for highlights, dark orange `#B4530A` for warnings and busy states. **Never use bright red** (it reads as danger or error to older users).
- **Personality:** calm, warm, respectful, trustworthy, Islamic but modern. Think of a well-kept masjid: clean lines, generous space, a touch of gold. Not flashy, not childish, not "techy".

## Non-negotiable accessibility rules

1. Body text at least **18sp**, headings 24sp+, main button labels 22sp+. Layouts must survive **200% system font size**.
2. Touch targets at least **56dp**, with 8dp+ spacing between them. Primary buttons are full width and about 64dp tall.
3. Contrast meets **WCAG AA** (4.5:1 for text). No grey text on coloured backgrounds, and no thin light fonts.
4. **Every icon has a visible text label.** No meaning is carried by colour alone, and no hidden gestures (swipe-only, long-press).
5. **One main action per screen.** Maximum **4 bottom tabs**, labels always visible. Settings sit behind a profile avatar, not a "More" tab.
6. **Arabic first:** every screen must work fully **mirrored (RTL)**. Quran text always uses an Uthmani (KFGQPC) font, never a UI font.
7. No gradients, no glassmorphism, no hamburger menus, no tiny thin icons.

## Phase 1: design system (approve before screens)

Deliver:
1. **Colour palette:** full token set (primary, on-primary, accent, background, surface, text, muted text, success, warning, selected and disabled states) with contrast ratios. Include a dark-mode variant.
2. **Typography:**
   - Arabic UI font and English UI font. Current choice: *IBM Plex Sans Arabic* and *Atkinson Hyperlegible*; suggest better pairings if they suit the logo.
   - The type scale in sp: display, headline, title, body, label.
   - Whether a serif such as the logo's "SANADI" style should be used for headings.
3. **Iconography:** one consistent icon style (filled vs outlined, stroke weight, rounded vs sharp). Icons needed: home, mushaf/Quran, athkar (sun), messages, students, microphone (recite), phone accept/decline, mute, speaker, end call, bookmark, play, settings/profile, morning, evening, after-salah, tasbeeh, sleep, waking, availability on/off, progress, report, warning.
4. **Components:** primary/secondary/text buttons (all states), the giant "Recite now" button, info card, availability toggle card, bottom navigation, app bar with profile avatar, list tile, selectable option card, dialog, empty state, status dot line, chips, form fields and pickers (for the teacher report), grade selector (Excellent / Good / Needs practice), and the dhikr counter button.
5. **App icon:** a simplified mark that stays readable at 48×48px on a home screen. The full calligraphy is too detailed at that size; explore using just the **س with its gold fatha**, or a gold-on-green monogram. Show it as an Android adaptive icon (foreground + background).
6. **Splash screen** using the logo.

## Phase 2: key screens (English LTR and Arabic RTL for each)

Priority order:
1. **Student home:** greeting; the giant **"Recite now / سمِّع الآن"** button (about 40% of the screen, microphone icon); "3 teachers available now" status line; "Your next portion: Al-Mulk 1–10" card with "Open in Quran"; "My teacher" card with availability dot and call button. Tabs: Home · Quran · Athkar · Messages.
2. **Connecting to a teacher:** calm "Finding a teacher for you…" animation, large Cancel.
3. **Incoming call (teacher):** full screen like a phone call: student name, session type, last portion and grade; large Accept (green) and Decline (dark orange).
4. **In call:** name, timer, connection quality, large Mute / Speaker / Open Quran, wide End call.
5. **Teacher home:** huge "I'm available to teach" toggle card; today's sessions and minutes; "5 students waiting" card. Tabs: Home · Students · Quran · Messages.
6. **Session report (teacher, after call):** portion recited (surah, from ayah, to ayah); grade buttons; mistakes as tappable ayah chips with tags; next portion; optional note (text or voice); sticky Submit. Must take under 30 seconds to fill in.
7. **My progress (student):** 30-juz grid coloured memorised / in progress / not started, with legend; next portion card; recent sessions list.
8. **Athkar menu:** six large full-width buttons with icons: Morning, Evening, After salah, Tasbeeh, Before sleep, On waking.
9. **Dhikr counter:** large Arabic text, transliteration toggle, meaning, source reference, a big round tap counter showing "1 / 3", progress through the set.
10. **Mushaf page:** Madani page on a warm cream background, minimal top bar (surah, juz, page), bottom bar (Play, Bookmark, Go to).
11. **Chat:** 1:1 with the teacher: large bubbles, voice-note bubble, big mic button, call button in the header.
12. **Onboarding:** language choice (shown in both languages), welcome with "Continue with Google", "I want to… memorise / teach", "I am… male / female" (with a note that this matches them with a same-gender teacher).
13. **Settings:** language, text-size preview, notifications, quiet hours, delete account, sign out.
14. **Empty, loading and error states** for Home, Messages and Students.

## Phase 3: handoff

For the approved designs, deliver:
- the design tokens (colours, type scale, spacing, radii, elevation) as a table **with exact values**
- component specs (sizes, padding, states)
- exported assets: app icon (adaptive layers), splash, any custom icons as SVG

These will be implemented in Flutter (Material 3). Standard Material components are preferred where they fit, styled to the brand.

## Checklist for every design

- [ ] Readable at arm's length on a small phone?
- [ ] Obvious what to tap first?
- [ ] Arabic version fully mirrored, with Arabic letters joined correctly?
- [ ] No grey-on-colour text, tiny icons or gradients?
- [ ] Would a 75-year-old know what to do without help?
