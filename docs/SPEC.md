# Sanadi (سَنَدي) — Product Spec v0.1

*Quran memorisation with volunteer teachers, built for elderly students.*
Status: draft for review · Platform: Android first (iOS later) · Languages: Arabic + English

---

## 1. Mission

Sanadi connects people who are memorising the Quran (mainly elderly men and women) with volunteer teachers of the same gender, who listen to their recitation on a live call and correct it. It is free, run as sadaqah jariyah.

**What we're improving on (Waratel):** slow, crashes, 77 MB, unnecessary permissions, password logins, small low-contrast text, the student has to browse teacher lists, session reports get lost in the chat, no progress tracking.

**Success means:**
- A 70-year-old can install the app, sign in and start a recitation call **without help** in under 3 minutes.
- At least 99.5% of sessions have no crash (measured by Crashlytics).
- The app is under 25 MB and opens in under 2 seconds on a budget Android phone.

---

## 2. Users

| Role | Who | Main goal |
|---|---|---|
| **Student** | Elderly man or woman, often a low-confidence phone user, Arabic or English speaker | Recite to a teacher and know what to memorise next |
| **Teacher** | Volunteer hafiz/hafiza, possibly with ijazah | Help students in their spare time with minimal admin |
| **Admin** | You (later, trusted helpers) | Approve teachers, handle reports, keep it safe |

Male students are only ever connected to male teachers, and female students to female teachers. **No exceptions in code.**

---

## 3. Design principles (non-negotiable)

1. **One main action per screen.**
2. **Text:** 18sp minimum body size, 22sp+ for headings, and the layout respects the phone's system font scale up to 200%.
3. **Touch targets:** at least 56dp, with 8dp+ spacing between them.
4. **Contrast:** meets WCAG AA (4.5:1). No grey text on coloured backgrounds.
5. **Every icon has a text label.** No actions hidden behind swipes or long-presses.
6. **Arabic first:** full RTL. Quran text always uses an Uthmani (KFGQPC) font.
7. **Confirm before destructive actions.** Undo where possible.
8. **Forgiving:** no passwords, no typing where a tap will do.
9. **Small and fast:** under 25 MB, works on Android 8+ phones with 2 GB RAM.
10. **Minimal permissions:** microphone and notifications only (camera later, if we add video).

---

## 4. Scope

### MVP (launch before Ramadan 2027)
- Google sign-in, onboarding (role, gender, language, name)
- Teacher application → admin approval
- Teacher availability switch
- **"Recite now"**: automatic matching and a ringing audio call
- Incoming call screen (full screen, works on the lock screen)
- Structured session report → student progress
- 1:1 chat (text + voice notes) between a student and their teachers
- Mushaf reader (offline after first download)
- Athkar: 6 categories, tap counter, morning/evening reminders
- Notifications: calls, messages, reminders
- Settings: language, text size preview, notifications, delete account
- Admin screens (in-app, admin role only)

### Later
Video calls · scheduled sessions · more languages (Urdu, French, Malay…) · athkar audio · teacher leaderboards/certificates · iOS · web admin dashboard · donations page

### Explicitly not doing
Payments · public profiles · group calls · social feed · ads (ever)

---

## 5. Navigation

**Student (4 tabs):** Home · Quran · Athkar · Messages
**Teacher (4 tabs):** Home · Students · Quran · Messages
**Profile/settings:** tap the avatar in the top corner (not a "More" tab).
**Admin:** an extra "Admin" entry in the profile menu for admin accounts only.

The bottom bar has large icons with labels always visible, and the selected tab is shown with colour **and** a filled icon (not colour alone).

---

## 6. Screens

### 6.1 Shared / onboarding

**S1 Splash:** logo, under 1 second.

**S2 Language:** two large buttons, "العربية" and "English". Defaults to the phone's language. The choice can be changed later.

**S3 Welcome / sign in:** logo, one line explaining the app, and a large **"Continue with Google"** button. Small links to the privacy policy and terms.

**S4 About you** (first sign-in only), one question per screen with progress dots:
1. "I want to…" → **Memorise / recite** (student) · **Teach as a volunteer** (teacher)
2. "I am…" → **Male** · **Female**. Shown with an explanation: *"So we can connect you with a teacher of the same gender."* Cannot be changed later without contacting the admin.
3. "What should we call you?" → name, pre-filled from Google
4. Teachers only: country, languages they speak, session types they offer (correction / memorisation and review / talqeen for beginners), optional ijazah details, optional short audio sample. → **"Application sent"** screen.

**S5 Pending approval (teacher):** "JazakAllahu khairan. We'll notify you when you're approved." The Quran and athkar are usable while waiting.

### 6.2 Student

**ST1 Home**
- Greeting: "As-salamu alaykum, {name}"
- **The giant "Recite now / اقرأ الآن" button**, about 40% of the screen
- Below it, the status line: "3 teachers available now" or "No teachers online — we'll notify you"
- **"Your next portion"** card: e.g. "Al-Mulk 1–10", from the last report. Tap → opens that page in the mushaf.
- **"My teacher"** card: their usual teacher's name and an availability dot. Small "Call {name}" button if available.
- When no teachers are online: a **"Notify me when a teacher is online"** toggle

**ST2 Choose session type** (bottom sheet after tapping Recite now, skippable via "Just connect me"):
Correction · Memorise / review · Learn to read (talqeen)

**ST3 Connecting:** "Finding a teacher…" with animation and a large **Cancel** button. The matching logic is in §7. If no one is found after 2 minutes: "No teacher is free right now. We'll notify you when someone comes online." → enable the notify toggle.

**ST4 In call**
- Teacher name, timer, connection quality indicator ("Good" / "Weak")
- Large buttons: **Mute**, **Speaker**, **Open mushaf** (opens the portion in split view or switches screen), **End call** (red, with confirmation)
- The screen stays awake. The call continues if the student leaves the app (ongoing notification).

**ST5 After call:** "May Allah reward you." Rate the session (3 large faces: 🙁 😐 🙂), optional. Then "Your teacher is writing your report" → when it arrives, a notification takes them to ST6.

**ST6 My progress**
- A visual map of 30 juz, or 114 surahs, coloured: memorised / in progress / not started
- List of past sessions: date, teacher, portion, grade, teacher notes. Tap for details.
- Next portion card

**ST7 Quran (mushaf)** — see §6.4

**ST8 Athkar** — see §6.5

**ST9 Messages**
- List of conversations with their teachers (only teachers they've had a session with)
- Chat: text, voice note (hold to record **or** tap to start/stop, since holding is hard for some users), and a call button if the teacher is available
- No images or files in the MVP (safety + moderation)

**ST10 Profile & settings**
Name · language · text size (preview slider) · notifications on/off · prayer-time-friendly quiet hours · "Notify me when teachers are online" · privacy policy · contact us (opens email) · **Delete my account** · sign out · app version

### 6.3 Teacher

**T1 Home**
- **Big availability switch:** "I'm available to teach" (green) / "I'm away" (grey)
- Today: sessions taught, minutes
- "Students waiting": count of students who tapped "notify me" (an encouragement to go online)
- Auto-off notice: "You missed 2 calls so we set you to away."

**T2 Incoming call** (full screen, rings even when locked)
Student name, session type, their last portion and grade · **Accept** / **Decline** · auto-decline after 30 seconds

**T3 In call** — same as ST4, plus a **"Student's portion"** button that opens the mushaf at their next portion.

**T4 Session report** (opens automatically after the call ends; must be fast, under 30 seconds)
- Portion recited: surah + from ayah → to ayah (pickers, pre-filled with the student's next portion)
- Type: correction / memorise / review / talqeen
- Grade: **Excellent · Good · Needs more practice** (large buttons)
- Mistakes (optional): tap ayahs in a mini list to flag them, and choose a tag: tajweed / memorisation / pronunciation
- Next portion: surah + ayah range (smart default: continue from where they stopped)
- Note to student (optional): text or voice note
- **Submit** · "Skip for now" (reminds later; reports pending over 24 hours show on T1)

**T5 Students:** list of students they've taught (name, last session, progress). Tap → that student's progress + history + chat.

**T6 Messages / T7 Quran / T8 Profile** — as for students, plus: session types offered, languages, availability hours (informational only in the MVP).

### 6.4 Mushaf (shared)
- Page view (604 pages, Madani layout), swipe to turn pages (RTL direction), plus a jump-to by surah / juz / page
- Rendered with QPC fonts from the Quranic Universal Library (QUL). **Downloaded after install** (~15–25 MB) to keep the install small. Prompted on first open, with a Wi-Fi recommendation.
- Tap an ayah → menu: play recitation · bookmark · "set as my next portion" (students)
- Audio: per-ayah recitation by a chosen reciter (EveryAyah / QF CDN), streamed and cached. Repeat ayah ×1/3/5/∞, speed 0.75–1.25×.
- Bookmark + "continue reading" position
- Night mode (sepia / dark)

### 6.5 Athkar (shared)
- 6 large full-width buttons with icons: Morning (sun) · Evening (moon) · After salah · Tasbeeh · Before sleep · On waking
- Each dhikr card: Arabic text (large), transliteration toggle, English meaning (in English mode), source reference (e.g. "Muslim 2723"), and a **count button** ("0 / 3"). Tapping counts with a soft vibration; it auto-advances when complete.
- Morning/evening reminder notifications (local, user-chosen times; defaults are after Fajr and after Asr)
- Content from authenticated Hisn al-Muslim data, bundled offline (licence checked before use)

### 6.6 Admin (in-app, admin role only)
- **Teacher applications:** listen to the audio sample, view details, Approve / Reject (with a reason)
- **Reports:** user reports of misconduct → view, warn, suspend
- **Users:** search, suspend / unsuspend, change gender (with a logged reason)
- **Stats:** active teachers, sessions per day, minutes, unmatched requests

---

## 7. Call & matching logic

```
Student taps "Recite now"
  → create callRequest {studentId, gender, type, status: searching}
  → candidate teachers = approved, same gender, available, not in a call,
     offering this session type
     ordered by: (1) the student's usual teacher, (2) teachers they've had before,
                 (3) fewest sessions today (spreads load fairly)
  → ring candidate #1 (high-priority FCM data message → full-screen call UI)
      accepted within 30s → connect WebRTC, status: active
      declined / timed out → mark missed, ring next candidate
  → after 2 min or no candidates left → status: unmatched
     → student offered "notify me when a teacher is online"
  → teacher with 2 consecutive missed calls → availability set to away + notice
Call ends → status: ended, duration saved → teacher gets the report form,
student gets the rating prompt
```

**Media:** WebRTC peer-to-peer, audio only (Opus codec). Signalling via Firestore. STUN: Google public servers. TURN: Cloudflare Realtime TURN (short-lived credentials issued by a Cloud Function). Automatic reconnection if the network drops for under 15 seconds ("Reconnecting…").
**Ringing:** `flutter_callkit_incoming` (Android full-screen intent + ConnectionService) so it behaves like a real phone call.
**Privacy:** calls are **not recorded**. Phone numbers are never shown or stored.

---

## 8. Data model (Firestore, first draft)

```
users/{uid}
  role: student|teacher|admin, gender: m|f, name, lang, country,
  createdAt, fcmTokens[], status: active|pending|suspended
  teacher: { approved, available, inCall, sessionTypes[], languages[],
             missedInRow, ijazah?, sampleAudioUrl? }
  student: { usualTeacherId?, nextPortion{surah,fromAyah,toAyah},
             notifyWhenAvailable }

callRequests/{id}
  studentId, gender, type, status: searching|ringing|active|ended|unmatched,
  candidateIds[], currentTeacherId, createdAt, startedAt, endedAt
  (subcollection: signaling/{msg} for WebRTC offer/answer/ICE)

sessions/{id}
  studentId, teacherId, type, startedAt, durationSec,
  report: { surah, fromAyah, toAyah, grade, mistakes[{ayah,tag}],
            nextPortion, note, voiceNoteUrl?, submittedAt },
  studentRating?

progress/{studentId}
  ayahStatus: compact map per surah (memorised / in progress), updated from reports

conversations/{id}   members[2], lastMessage, unread{uid:n}
  messages/{id}      senderId, type: text|voice, text?, audioUrl?, durationSec?, sentAt

reports/{id}         reporterId, reportedId, reason, context, status
```

**Security rules:** users read/write only their own data; conversations only between people who've had a session; gender match enforced server-side in matching (Cloud Function), not just in the app.

---

## 9. Notifications

| Event | Type | Recipient |
|---|---|---|
| Incoming call | Full-screen, high priority | Teacher |
| Missed call | Normal | Teacher |
| Session report ready | Normal | Student |
| New message | Normal (grouped per conversation) | Both |
| A teacher is now online | Normal, max 1 per hour | Students with "notify me" on |
| Teacher approved / rejected | Normal | Teacher |
| Athkar reminders | Local, scheduled | Opted-in users |
| Pending reports reminder | Normal, once a day max | Teacher |

Notification channels are separated (Calls / Messages / Reminders) so users can silence one without losing calls.

---

## 10. Tech stack

| Area | Choice |
|---|---|
| App | Flutter (Dart), Material 3, Riverpod (state), go_router |
| Auth | Firebase Auth + Google Sign-In |
| Data | Cloud Firestore (offline persistence on) |
| Files | Firebase Storage (voice notes, teacher samples) |
| Backend logic | Cloud Functions (matching, TURN credentials, notifications, counters) |
| Push | Firebase Cloud Messaging |
| Calls | flutter_webrtc + Cloudflare TURN + flutter_callkit_incoming |
| Quran | QUL / Quran Foundation data + KFGQPC fonts, EveryAyah audio |
| Localisation | Flutter intl (ARB files): `ar`, `en` |
| Quality | Crashlytics, Performance Monitoring, Analytics (privacy-respecting, no ads ID) |
| CI | GitHub Actions: analyse + test + build APK/AAB on every push |
| Package name | `sanadi.quran` (**confirmed, permanent once published**) |
| Min Android | 8.0 (API 26) |

Monthly cost target: **R0** at launch, with a Firebase budget alert at R100.

---

## 11. Visual direction (to be confirmed with the logo)

- **Primary:** deep green `#1F5E4B` (trust, Islam), **Accent:** warm gold `#C8A04A`, **Background:** warm off-white `#FAF7F0`, **Text:** near-black `#1B1B1B`. Busy/error states use dark orange, not bright red.
- **Fonts:** UI in Arabic = *IBM Plex Sans Arabic* or *Noto Naskh Arabic*. UI in English = *Atkinson Hyperlegible* (designed for low vision). Quran = KFGQPC Uthmani.
- **Feel:** calm, generous whitespace, rounded cards (16dp radius), no gradients, gentle motion only.
- **Dark mode:** supported, but light is the default.

---

## 12. Safety & privacy

- Gender separation enforced on the server
- No profile photos in the MVP (the avatar is an initial/icon). No phone numbers. No images in chat.
- Report + block on every chat and after every call
- Teachers are approved manually; admin can suspend instantly
- Calls are not recorded; voice notes can be deleted by the sender
- Account deletion in-app (Google Play requirement) deletes personal data within 30 days
- Privacy policy hosted on Firebase Hosting (required for the Play listing)

---

## 13. Google Play requirements checklist
- Privacy policy URL · Data safety form · account deletion (in-app + web link)
- Full-screen intent declaration (calling app) · foreground service type `phoneCall` / `microphone`
- Closed test: 12+ testers for 14 days (personal developer account)
- Target the latest required API level · AAB upload · content rating questionnaire

---

## 14. Milestones

| When | Milestone |
|---|---|
| Oct wk 2 | Spec signed off · design directions explored · repo + CI set up |
| Oct wk 3–4 | Design rules locked · clickable prototype tested with 2–3 elders · Flutter shell (theme, RTL, i18n, navigation) · mushaf + athkar |
| Nov | Firebase: sign-in, onboarding, teacher approval, chat + voice notes, notifications |
| Dec | Calls: matching, ringing, WebRTC, reconnection · session reports · progress |
| Early Jan | Admin, polish, accessibility pass, performance on a cheap phone |
| Jan (14 days) | Closed test with 12+ testers (5 teachers, 10 students) |
| Late Jan / early Feb | Public launch on Google Play, before Ramadan (~8 Feb 2027) |

---

## 15. Open questions
1. ~~Package name~~ — confirmed: `sanadi.quran`.
2. Should students be able to pick a specific teacher from a list (optional browsing), or only use "Recite now" and "My teacher"?
3. Teacher verification: is an audio sample enough, or do we require an ijazah or a reference?
4. Which reciter(s) to offer by default in the mushaf audio?
5. Countries to enable at launch: all, or SA + the Arab countries first?
6. Minimum age for students and teachers (affects the Play content rating and safety)?
