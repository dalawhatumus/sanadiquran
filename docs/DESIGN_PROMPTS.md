# Sanadi: design prompts for Google Stitch / Claude Design

How to use: paste the **Base style** block first, then one screen prompt at a time. Generate 2–3 variations of each, then send screenshots back for review. Do the Arabic version too, since that's where most tools break.

---

## Base style (paste this first, every time)

> Design an Android mobile app called **Sanadi (سَنَدي)**, a free Quran memorisation app that connects **elderly** students with volunteer Quran teachers through live audio calls.
>
> **Audience:** men and women aged 55–85 with low confidence on phones and possibly weak eyesight. Design for them, not for young tech users.
>
> **Hard rules:**
> - Body text at least 18sp, headings 24sp+, main button labels 22sp+
> - Every button at least 56dp tall, full width where possible, with generous spacing
> - High contrast (WCAG AA): dark text on light backgrounds; no grey text on coloured backgrounds
> - Every icon has a visible text label
> - One main action per screen; lots of whitespace; nothing crowded
> - No gradients, no glassmorphism, no tiny thin icons, no hamburger menus
> - Bottom navigation with at most 4 tabs, with labels always visible
>
> **Style:** calm, warm, respectful, Islamic but modern. Primary deep green #1F5E4B, accent warm gold #C8A04A, background warm off-white #FAF7F0, text #1B1B1B. Rounded cards (16dp radius), soft shadows. Busy/warning states use dark orange, never bright red. Font: Atkinson Hyperlegible (English) / IBM Plex Sans Arabic (Arabic).
>
> Generate in **English (LTR)** first, then the same screen in **Arabic (RTL, fully mirrored layout)**.

---

## Screen prompts

### 1. Welcome / sign in
> Welcome screen: Sanadi logo placeholder at the top centre, the app name "Sanadi · سَنَدي" below it, one short line "Recite the Quran to a teacher, anytime." A large full-width "Continue with Google" button with the Google logo. Small text links at the bottom: Privacy policy · Terms. Nothing else.

### 2. Onboarding question ("I am…")
> Onboarding step 2 of 4 (progress dots at top). Title "I am…". Two very large selectable cards stacked vertically: "Male / ذكر" and "Female / أنثى", each with a simple icon. Explanation text below: "So we can connect you with a teacher of the same gender." A large "Next" button at the bottom, disabled until a choice is made. Back arrow with the label "Back".

### 3. Student home (most important screen)
> Student home screen. Top: greeting "As-salamu alaykum, Fatima" with a small round avatar (initial letter) in the corner for settings. The centrepiece is ONE huge circular or rounded-square green button taking about 40% of the screen, with a microphone icon and the label "Recite now". Under it, small status text with a green dot: "3 teachers available now". Below, two cards: (1) "Your next portion: Surah Al-Mulk, ayahs 1–10" with an "Open in Quran" button; (2) "My teacher: Ustadha Aisha" with a green "Available" dot and a "Call" button. Bottom navigation with 4 labelled tabs: Home, Quran, Athkar, Messages.

### 4. Connecting to a teacher
> Full-screen state "Finding a teacher for you…" with a gentle pulsing circle animation around a microphone icon, on the green background with white text. Small text "This usually takes less than a minute." A large white outlined "Cancel" button at the bottom.

### 5. Incoming call (teacher's phone)
> Full-screen incoming call, like a phone call. Top: "Sanadi · Recitation call". Centre: student initial avatar, the name "Hajja Maryam", session type "Memorisation & review", and "Last portion: Al-Mulk 1–10 · Good". Bottom: two very large round buttons with labels, "Decline" (dark orange) on one side and "Accept" (green) on the other.

### 6. In call
> Active audio call screen. Top: teacher name "Ustadha Aisha", timer "12:34", connection indicator "Good connection". Centre: a large avatar. Bottom: a grid of 3 large labelled round buttons, "Mute", "Speaker", "Open Quran", and below them a wide "End call" button in dark orange. Calm and uncluttered.

### 7. Session report (teacher fills after the call)
> Teacher's quick session report form, one scrollable page. Sections with large controls: "Portion recited" (Surah dropdown: Al-Mulk, From ayah 1, To ayah 10); "Grade" with three large toggle buttons "Excellent", "Good", "Needs practice"; "Mistakes (optional)" showing a short list of ayah numbers as tappable chips; "Next portion" (Surah dropdown + ayah range); "Note to student (optional)" with a text field and a microphone button for a voice note. A sticky full-width "Submit report" button at the bottom, with a text button "Skip for now".

### 8. My progress (student)
> Progress screen titled "My progress". Top: a summary "You have memorised 4 surahs · 312 ayahs". A visual grid of 30 rounded squares labelled 1–30 (juz), coloured green = memorised, gold = in progress, light grey = not started, with a legend. Below: the "Your next portion" card, then a list "Recent sessions" with cards showing date, teacher name, portion, and a grade badge.

### 9. Teacher home
> Teacher home screen. Top greeting "As-salamu alaykum, Ustadh Yusuf". The centrepiece is a huge toggle card: when on, green with the text "You are available to teach" and a large switch; when off, grey with "You are away". Below: a stats row "Today: 3 sessions · 54 minutes", and a highlighted card "5 students are waiting for a teacher". Bottom navigation: Home, Students, Quran, Messages.

### 10. Athkar menu
> Athkar screen titled "Athkar · الأذكار". Six large full-width buttons stacked vertically, each with an icon and a label: Morning (sun), Evening (moon), After salah (prayer mat), Tasbeeh (prayer beads), Before sleep (bed/crescent), On waking (sunrise). At the top, a small card "Next reminder: Evening athkar at 16:30".

### 11. Dhikr counter
> Single dhikr screen. Large Arabic text of the dhikr centred in a card with comfortable line height, a transliteration toggle, and the English meaning in smaller text below. The source reference "Muslim 2723" in small text. At the bottom, a very large round counter button showing "1 / 3" that the user taps to count. Progress text at the top: "Morning athkar · 4 of 24". Previous/Next arrows with labels.

### 12. Mushaf page
> Quran reading screen showing one Madani mushaf page with Uthmani Arabic script on a warm cream background, with a surah header ornament. A minimal top bar: surah name "Al-Mulk", "Juz 29", "Page 562". A minimal bottom bar with labelled buttons: "Play", "Bookmark", "Go to". The page fills most of the screen.

### 13. Chat
> 1:1 chat between a student and teacher Ustadha Aisha. The header has the teacher's name, a green "Available" dot and a large "Call" button. Message bubbles with large text, including one voice note bubble with a play button and duration "0:42". The bottom input bar has a text field "Type a message…" and a large microphone button labelled "Voice".

---

## After generating, check every design for
- [ ] Is the text big enough to read at arm's length?
- [ ] Is it obvious what to tap first?
- [ ] Is the Arabic version fully mirrored, with letters joined correctly?
- [ ] Did the tool sneak in grey text, tiny icons or gradients?
- [ ] Would your mother or grandmother know what to do?
