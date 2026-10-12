# Sanadi security model

## Who can do what (enforced by `firebase/firestore.rules`)

Nothing can be read or written without signing in (Google sign-in through
Firebase Auth). Beyond that:

| Data | Read | Write |
| --- | --- | --- |
| Profile `users/{uid}` | the person, admins | the person only. Name ≤ 80, a known role, picture and language. **Gender can be set once and never changed**, because it decides who can call whom. |
| Teacher application, voice sample | the applicant, admins | the applicant sends or resends (same gender as their profile, limited sizes). Only an admin approves or turns it down, signing it with their own id. An approved application can't be edited. |
| Availability `presence/{uid}` | anyone signed in (only a count is shown) | approved teachers only, with the gender of their **approved application** |
| Conversations and messages | the two members (admins can read conversations) | only an admin or a finished call opens one, between a student and a teacher of the same gender. Members change only the preview, unread counts, **their own** name and picture, and their own block. Messages are sent by the sender only (text ≤ 2000, voice ≤ ~3 min). Deleting is allowed for your own messages only. |
| Calls | the student and the teacher being rung | the student rings approved teachers whose **application** gender matches. The teacher answers or declines. Neither side can change the other's fields. |
| Lessons | the two people in it | saved only for a real call between them. Notes are written by the teacher (validated), the rating by the student. |
| Reports | admins | anyone may report the other member of **their own** chat, with a known reason (details ≤ 1000). Admins can only change the status. |
| Paused accounts `suspensions/{uid}` | the person, admins | admins only (with a reason, signed with their id). A paused person can't send messages, start or answer calls, switch on "available", or apply to teach; nobody can ring a paused teacher. Restoring deletes the record. |
| Admins | the admin themself | nobody (added by hand in the console) |

Every rule has emulator tests in `firebase/test/rules.test.mjs`, including
attempts to break it.

## Sign-in and account deletion

- **Sign-in:** Google sign-in only. No passwords are handled or stored by
  the app.
- **Deleting an account:** this requires a recent sign-in. The app confirms
  it by **re-authenticating** the signed-in account before deleting
  anything. Firebase refuses a different Google account, so only your own
  account can ever be deleted, and cancelling leaves everything unchanged.

## On the phone

- **No backups:** Android backup and device transfer are switched off
  (`allowBackup=false`, `data_extraction_rules.xml`). Sign-in tokens,
  cached chats and settings never leave the phone.
- **Encrypted connections only:** plain http is blocked
  (`usesCleartextTraffic=false`).
- **Signing out or deleting the account** clears that person's local data:
  settings and profile, chosen next portion, cached voice notes and
  recordings (`forgetUserOnThisPhone`). Phone-wide choices such as reciter
  and reminder times are kept.
- **File names** built from server ids are sanitised (`LocalFiles.safeName`).
- **Damaged saved data** never crashes the app; it starts fresh instead.
- **Reminder notifications** can only open the morning or evening athkar
  (an allow-list), never any other screen.
- **Logging:** release builds write nothing to the system log
  (`logIssue`).

## Secrets

The app signing key, its password and the TURN credential live only in
GitHub Secrets. The Firebase settings are build-time variables. None of
these are in the repository, and `.gitignore` blocks key files (`*.jks`,
`*.keystore`, `key.properties`, `.env`).

## Known limits (accepted for now)

- Firestore's offline cache stays in the app's private storage after
  sign-out. Other apps can't read it, and the rules still decide what the
  next user can see from the server.
- A student's gender is self-declared. Teachers are checked by an admin
  when their application is approved.
- Calls only ring while the teacher's app is open (free plan, no push).
