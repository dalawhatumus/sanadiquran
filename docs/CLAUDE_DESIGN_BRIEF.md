# Sanadi: complete design brief for Claude Design

**How to use:** paste everything below the line into Claude Design and attach the files in `assets/brand/`: the logo set, the app icon and the colour/font sheet. Work phase by phase, and don't start screens until Phase 1 is approved. **Every screen in Section 6 must be designed**: the full user journey for students, teachers and admin, plus every settings screen and every empty, loading and error state.

---

## 1. The product

**Sanadi (سَنَدي)** means "my support" and "my chain of transmission". It is a free Android app, built as sadaqah jariyah, that connects **elderly Muslims memorising the Quran** with **volunteer teachers of the same gender**.

**The core loop:**
1. The student taps one giant **"Recite now"** button.
2. The app rings an available same-gender teacher.
3. They recite on a live audio call.
4. The teacher logs a 20-second report.
5. The student sees their progress and "your next portion".

**The app also includes:**
- a mushaf (Quran reader with audio)
- athkar with a tap counter and reminders
- 1:1 messaging between student and teacher
- an admin area for approving teachers

**The competitor (Waratel):** slow, cluttered, small grey text, password logins, students forced to browse long teacher lists, red buttons, reports lost in chat, no progress tracking. Sanadi must feel **calm, dignified, obvious and fast**: the opposite in every way.

## 2. Who we design for

- **Students:** men and women aged **55–85**. Many have weak eyesight, shaky hands, low confidence with phones and fear of "pressing the wrong thing". They use Arabic or English, live in the Arab world or South Africa, and have budget Android phones (360×800dp), often with the system font set large.
- **Teachers:** volunteer huffaz of all ages who want minimal admin.
- **Admin:** the app owner, approving teachers and handling reports.

**Design test for every screen:** could a 75-year-old grandmother, with no one helping her, understand what this screen is and what to tap, within 5 seconds?

## 3. Non-negotiable design criteria

1. **Text size:** body ≥ **18sp**, headings ≥ 24sp, main button labels ≥ 22sp. Every screen must still work at **200% system font size**; show the student home and teacher report at 200% to prove it.
2. **Touch targets:** ≥ **56dp**, with ≥ 8dp between them. Primary buttons are full width and about 64dp tall. Nothing tiny, nothing crowded.
3. **Contrast:** WCAG AA (≥ 4.5:1 for text, ≥ 3:1 for icons and borders). No grey text on coloured backgrounds, and no thin or light font weights.
4. **One main action per screen.** The primary action is visually dominant, and secondary actions are clearly secondary.
5. **Navigation:** at most **4 bottom tabs**, labels always visible. Settings live behind the **profile avatar** in the top corner, never in a "More" tab or hamburger menu.
6. **No hidden interactions:** every action is a visible, labelled button. No swipe-only, long-press-only or double-tap actions.
7. **Colour is never the only signal:** state is always shown with an icon or text as well (e.g. a green dot plus the word "Available").
8. **Arabic first:** every screen is designed **in Arabic (RTL, fully mirrored)** and in English (LTR). Arabic letters must join correctly. Quran text always uses an **Uthmani (KFGQPC) font**, never a UI font.
9. **Forgiving:**
   - confirm destructive actions, and offer undo where possible
   - no passwords and no typing where a tap will do
   - plain, warm language, never technical ("Something went wrong. Please try again", not "Error 500")
10. **Calm visuals:** no gradients, glassmorphism, neon, busy patterns or tiny decorative elements. Generous whitespace. Gentle motion only, and nothing flashing.
11. **Never bright red.** Use dark orange for warnings, end call and busy states. Red reads as danger and frightens older users.
12. **Privacy and modesty:** no profile photos of people. Avatars are initials or simple icons. No illustrations of faces or bodies.

## 4. Iconography: it must be meaningful to older people

Icons are a key accessibility tool here, not decoration. Rules:

- **Literal, familiar metaphors** that people over 60 already know from phones, home and masjid life, not abstract tech symbols.
- **Always paired with a visible text label.** An icon alone is never enough.
- **One consistent style:** **filled**, rounded, bold strokes, sized 28–32dp in navigation and up to 48–64dp on primary buttons. No thin outline icons; they disappear for weak eyes.
- **Culturally appropriate:** Islamic and everyday metaphors, no faces or people, no musical notes for Quran audio.
- **Test each icon:** would someone who doesn't use apps guess its meaning from the picture alone? If not, redesign it.

| Meaning | Use this metaphor | Avoid |
|---|---|---|
| Home | A simple house | A mosque (confusing as "home"), a grid of dots |
| Recite now (main action) | A large **microphone** | A play triangle, a waveform |
| Quran / mushaf | An **open book on a rehal (book stand)** | A closed generic book, a document icon |
| Athkar | **Prayer beads (misbaha)** or a sun-and-moon pair | A star, a heart |
| Messages | A **speech bubble** | An envelope (reads as "email"), a paper plane |
| Call / accept call | A classic **phone handset**, green | A video camera |
| End call / decline | A **handset tilted down**, dark orange | A red X |
| Mute | A **microphone with a slash** | A speaker with a slash (that's volume) |
| Speaker | A **loudspeaker with sound waves** | Headphones |
| My students | **Two simple figures without faces**, or a group of circles | Detailed people, faces |
| Progress | A **mushaf with a filled bookmark**, or a filling path | A bar chart (too abstract) |
| Teacher available | A **green dot plus the word "Available"** | Colour alone |
| Session report | A **clipboard with a tick** | A pie chart |
| Next portion | A **bookmark ribbon** | An arrow |
| Morning athkar | **Sun** | |
| Evening athkar | **Moon and stars** | |
| After salah | A **prayer mat** | A clock |
| Tasbeeh | **Prayer beads** | A finger tap |
| Before sleep | A **crescent moon over a pillow** | Zzz |
| On waking | A **sunrise** | An alarm clock |
| Settings / profile | A **person-in-circle avatar** with a "Settings" label | A cog alone |
| Language | **"ع / A"** characters | A globe alone |
| Text size | **"A A"** in two sizes | A magnifier |
| Notifications | A **bell** | |
| Help | A **question mark in a circle** with the label "Help" | An "i" |
| Delete account | A **bin** inside a confirmation flow | |
| Back | An **arrow plus the word "Back"**, mirrored in RTL | A chevron alone |

Deliver the full icon set as SVG on a 24dp grid, in filled style, with LTR and RTL variants where direction matters (back, next, send).

## 5. Brand

**Attach these files** (all in `assets/brand/` of the repo):
- `sanadi-brand-sheet.png`: the overview of everything below
- `svg/sanadi-horizontal-green.svg` and `png/sanadi-horizontal-green.png`: primary logo (vector, plus a 4096px transparent PNG)
- `svg/sanadi-vertical-green.svg`: stacked logo
- `svg/sanadi-mark-green.svg`: the mark only (سَ over an open book)
- `svg/sanadi-horizontal-cream.svg` and `svg/sanadi-vertical-cream.svg`: reversed versions for green backgrounds
- `app-icon/app-icon.svg` (plus its foreground and background layers) and `app-icon/play-store-icon-512.png`

**The logo:** the mark is a flowing calligraphic **سَ** (with its fatha) whose long stroke sweeps down to become the pages of an **open book**: the student's *sanad* (support, chain of transmission) growing out of the Quran. The owner's original artwork is in `source/`; the files in `svg/` and `png/` are an exact vector trace of it. The wordmark is **سَنَدي** in Tajawal Bold with both fathas, over a spaced **SANADI** in Montserrat. Variations:
- horizontal (mark left), and horizontal with the mark on the right for Arabic layouts
- vertical/stacked, mark only, wordmark only
- colour versions: green, deep green, cream (reversed), black and white

**App icon:** the mark in cream on Sanadi Green, sized inside Android's adaptive-icon safe zone and tested in circle and rounded-square masks down to 48px. Use the vertical reversed logo on the splash screen.

**Colours** (already checked against Section 3; use exactly these):

| Token | Hex | Use | Contrast on cream |
|---|---|---|---|
| Sanadi Green | `#026C3B` | Primary, buttons, logo, selected tab | 5.8 : 1 ✓ |
| Deep Green | `#0D4A3C` | Headings, pressed states, splash background | 9.0 : 1 ✓ |
| Slate | `#1E3A40` | Body text, dark surfaces | 10.7 : 1 ✓ |
| Sage | `#8FAE9E` | **Decoration only:** dividers, illustrations, large surfaces | 2.1 : 1 ✗ never for text or icons |
| Sage Dark | `#4F6F60` | Secondary or muted text (use instead of sage) | 4.9 : 1 ✓ |
| Sage Tint | `#DDE8E1` | Selected states, chips, highlighted cards | slate on it 9.6 : 1 ✓ |
| Cream | `#F4F0E8` | App background | — |
| White | `#FFFFFF` | Cards and sheets | — |
| Warning | `#A04A0A` | End call, decline, busy, errors (never bright red) | 5.3 : 1 ✓ |

Propose dark-mode equivalents that keep the same contrast levels.

**Fonts:**
- **Arabic UI: Tajawal**, Medium 500 for body, Bold 700 for headings.
- **English UI: Montserrat**, Medium 500 for body, Bold 700 for headings.
- **Never use Light, Thin or ExtraLight weights.** Montserrat is wide, so check that layouts still hold at 200% text size.
- **Quran text:** an Uthmani KFGQPC font only.

**Personality:** calm, warm, respectful, trustworthy, Islamic but modern. Think of a well-kept masjid: clean lines, generous space, quiet greens on warm cream. Not flashy, not childish, not "techy".

**Always write the Arabic name with its vowel marks: سَنَدي.** Without them it can be read as "Sindi". Never recolour, stretch, outline or add shadows to the logo.

## 6. Every screen to design

Design each screen on a **360×800dp Android frame**, in **Arabic and English**. Key screens (marked ★) also need a **dark-mode** version and a **200% font** version. For each screen, show the default state plus the listed states.

### 6.1 First launch and onboarding (shared)
1. **Splash:** logo on brand background.
2. **Choose language:** shown in both languages at once ("اختر لغتك / Choose your language"), with two large buttons: العربية, English.
3. **Welcome:** logo, one-line purpose ("Recite the Quran to a teacher, anytime"), **Continue with Google**, and small links to the privacy policy and terms. *States:* signing in (loading), sign-in failed, no internet.
4. **What would you like to do?** Two big cards: "Memorise and recite" (student) or "Teach as a volunteer" (teacher).
5. **I am…** Male / Female, with the note "So we can connect you with a teacher of the same gender. This can't be changed later."
6. **Your name:** pre-filled from the Google account, editable, large field.
7. **Permission explainers,** shown *before* the system pop-ups, with a friendly illustration and a "Continue" button:
   - microphone ("So your teacher can hear you recite")
   - notifications ("So you know when your teacher calls or messages")
   - full-screen calls (teacher only)
8. **Permission denied:** a gentle explanation plus an "Open settings" button.
9. **Short welcome tour (students, optional, 3 cards):** how Recite now works, your progress, athkar. "Skip" is always visible.

**Teacher application** (after step 6 for teachers):
10. Country and languages spoken (large chips).
11. Session types offered: Correction / Memorise & review / Talqeen (learn to read).
12. Ijazah or qualification (optional, plain text).
13. Record a short recitation sample. *States:* ready, recording (with timer), recorded (play back / re-record), uploading.
14. **Application sent:** warm thank-you ("JazakAllahu khairan, we'll notify you when you're approved").
15. **Pending approval** home: the mushaf and athkar are usable while waiting.
16. **Application not approved:** kind message plus the reason, and "Contact us".

### 6.2 Student journey
17. ★ **Student home:**
   - greeting
   - the **giant "Recite now / سمِّع الآن" button** (about 40% of the screen, microphone icon)
   - status line ("3 teachers available now")
   - "Your next portion" card with "Open in Quran"
   - "My teacher" card with availability and a "Call" button
   *States:*
   - first time (no teacher yet, no portion)
   - teachers available
   - no teachers online, with a "Notify me when a teacher is online" toggle
   - usual teacher online
   - offline (no internet)
18. **Choose session type** (bottom sheet): Correction / Memorise & review / Learn to read, plus a big "Just connect me".
19. ★ **Connecting:** calm "Finding a teacher for you…" animation, "This usually takes less than a minute", large Cancel. *States:* ringing teacher, trying another teacher.
20. **No teacher available:** "No teacher is free right now. We'll notify you as soon as one comes online." Notify toggle and a "Back to home" button.
21. ★ **In call (student):**
   - teacher name, timer, connection quality in words ("Good connection")
   - large **Mute**, **Speaker** and **Open Quran** buttons, and a wide **End call** (dark orange, with confirmation)
   *States:*
   - connecting
   - active
   - muted
   - weak connection
   - reconnecting ("Reconnecting… please wait")
   - call failed
22. **In call with mushaf open:** split or overlay view showing the portion page, with call controls still reachable.
23. **End call confirmation:** "End this session?" Yes / No.
24. **Call ended:** "May Allah reward you", duration, optional rating with 3 large faces (Not good / OK / Good), "Done".
25. **Report ready:** notification plus a screen showing:
   - the portion recited and the grade (Excellent / Good / Needs practice)
   - mistakes highlighted by ayah, with tags
   - the next portion and the teacher's note (text or voice)
26. ★ **My progress:** summary ("4 surahs · 312 ayahs memorised"), a **30-juz grid** (memorised / in progress / not started, with legend and labels), the next portion card, and recent sessions. *States:* empty (before the first session).
27. **Session history:** list by month.
28. **Session detail:** the full report for one past session.
29. **My teachers:** teachers they've recited to, each with availability and a "Call" or "Message" button.

### 6.3 Teacher journey
30. ★ **Teacher home:** huge **"I'm available to teach"** toggle card (on is green with a gold accent; off is neutral grey with "You are away"), today's sessions and minutes, and a "5 students waiting for a teacher" card. *States:* available, away, auto-away notice ("You missed 2 calls, so we set you to away"), pending reports reminder.
31. ★ **Incoming call:** full screen, like a phone call, and also as a **lock-screen version**. Shows the student name, session type, last portion and grade; large **Accept** (green) and **Decline** (dark orange). *States:* ringing, auto-declined after 30 seconds.
32. **In call (teacher):** like 21, plus a **"Student's portion"** button that opens the mushaf at their portion.
33. **Missed call:** notification and a list entry.
34. ★ **Session report form** (opens after the call; must take under 30 seconds):
   - portion recited (surah / from ayah / to ayah pickers, pre-filled)
   - session type
   - grade with 3 big buttons
   - mistakes: tap ayah chips and choose a tag (Tajweed / Memorisation / Pronunciation)
   - next portion (smart default)
   - optional note as text or a recorded voice note
   - sticky **Submit**, plus "Skip for now"
   *States:* validation (missing grade), submitting, submitted.
35. **My students:** list with name, last session, progress at a glance. *State:* empty.
36. **Student detail:** that student's progress grid, history and "Message" button.

### 6.4 Shared features
37. **Quran: surah index**, with search and juz / surah / page tabs, large rows.
38. **Quran: juz index.**
39. ★ **Quran: mushaf page:** Madani page on warm cream, minimal top bar (surah, juz, page), bottom bar (Play, Bookmark, Go to). *States:* night / sepia mode.
40. **Ayah menu** (after tapping an ayah): Play from here, Bookmark, Set as my next portion (students).
41. **Audio player bar:** play/pause, repeat ayah ×1/3/5/∞, speed 0.75–1.25×, reciter name.
42. **Choose reciter.**
43. **Mushaf download prompt:** size, Wi-Fi recommendation, progress, done.
44. **Bookmarks list.**
45. ★ **Athkar menu:** 6 large full-width buttons (Morning, Evening, After salah, Tasbeeh, Before sleep, On waking) plus a "Next reminder" card.
46. ★ **Dhikr counter:**
   - large Arabic text, a transliteration toggle, the meaning and the source reference
   - a **giant round tap counter** ("1 / 3") with soft vibration
   - Previous / Next, and progress ("4 of 24")
47. **Athkar set complete:** gentle completion screen ("May Allah accept"), "Back to athkar".
48. **Messages list:** conversations with teachers or students, unread badges. *State:* empty.
49. **Chat:**
   - text bubbles (large), and voice note bubbles with play and duration
   - **tap to record** (not hold), with a recording state and Cancel / Send
   - "Call" button in the header
   *States:* sending, failed to send (retry), teacher offline.
50. **Report or block a user:** reason options, confirmation, done.

### 6.5 Settings (every screen)
51. **Settings home** (from the profile avatar): name and role at the top, then grouped rows.
52. **Language:** العربية / English, with a live preview.
53. **Text size:** explanation plus a live preview of a sample screen at different sizes, and a link to the phone's display settings.
54. **Notifications:** separate switches for Calls, Messages, Reminders and "A teacher is online".
55. **Quiet hours:** start and end time pickers (large wheels), with presets around prayer times.
56. **Athkar reminders:** morning and evening times, on/off.
57. **Quran settings:** default reciter, night mode, downloaded mushaf and audio storage with a delete option.
58. **Teacher settings:** session types offered, languages, usual availability hours (informational).
59. **Privacy and safety:** who can message me, blocked users list (unblock), how we keep you safe.
60. **Help and contact:** FAQ with large expandable items, "Contact us" (email), "Report a problem".
61. **About Sanadi:** the sadaqah jariyah message, version, acknowledgements (Quran data, fonts, reciters).
62. **Privacy policy** and **Terms:** readable long-text screens.
63. **Sign out:** confirmation.
64. **Delete account:** an explanation of what will be deleted, a confirmation step (tick "I understand" plus "Delete"), and a done screen.

### 6.6 Admin (admin accounts only)
65. **Admin home:** counts (pending applications, open reports, active teachers, sessions today).
66. **Teacher applications list.**
67. **Application detail:** details, play the audio sample, Approve / Reject (with reason).
68. **Reports list** and **report detail:** context, Warn / Suspend / Dismiss.
69. **Users search** and **user detail:** suspend or unsuspend, change gender (with a logged reason).

### 6.7 System states and notifications
70. **No internet** banner and full-screen state.
71. **Loading** skeletons for home, lists and the mushaf.
72. **Generic error** with "Try again".
73. **Update required** screen.
74. **Android notification designs:** incoming call (full-screen intent), missed call, new message, report ready, teacher now online, athkar reminder, application approved.
75. **Snackbars/toasts and confirmation dialogs:** standard patterns.

## 7. Deliverables and phases

**Phase 1: design system (approve before screens)**
- **Colour tokens:** primary, on-primary, accent, background, surface, text, muted text, success, warning, selected, disabled; light and dark, with contrast ratios.
- **Typography:**
  - Arabic and English UI fonts
  - the full type scale in sp
  - the Quran font
  - where (if anywhere) the logo's display font may be used
- **Spacing scale, radii and elevation.**
- **Icon set** (Section 4) as SVG.
- **Components with all states:**
  - buttons: primary, secondary, text and destructive
  - the giant Recite button and the availability toggle card
  - cards, list rows, the bottom navigation and the app bar with avatar
  - chips, form fields, pickers, the grade selector and the dhikr counter
  - dialogs, bottom sheets, snackbars, the status line and empty states
- **App icon** (adaptive: foreground and background layers) and **splash.**

**Phase 2: all screens in Section 6,** in priority order: 17, 19, 21, 30, 31, 34, 26, 45, 46, 39, then the rest.

**Phase 3: handoff:**
- a token table with exact values
- component specs (sizes, padding, states)
- the flow diagram of the full user journey
- exported SVG and PNG assets

The app is built in **Flutter (Material 3)**. Prefer Material components styled to the brand.

## 8. Checklist for every screen
- [ ] Readable at arm's length on a small phone, and still works at 200% text?
- [ ] One obvious primary action?
- [ ] Every icon labelled and meaningful to someone who doesn't use apps?
- [ ] Arabic version fully mirrored, with letters joined correctly?
- [ ] No grey-on-colour text, thin icons, gradients or bright red?
- [ ] Would a 75-year-old know what to do without help?
