// Everything the admin portal reads from and writes to Firestore. It uses
// the same database and security rules as the app: only accounts listed
// in /admins can read or change anything here.
import { initializeApp } from './vendor/firebase-app.js';
import {
  getAuth, onAuthStateChanged, signInWithPopup, signInWithCustomToken, GoogleAuthProvider, signOut,
  connectAuthEmulator,
} from './vendor/firebase-auth.js';
import {
  getFirestore, connectFirestoreEmulator, collection, doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc,
  addDoc, query, where, orderBy, limit, writeBatch, serverTimestamp, Timestamp, getCountFromServer,
  getAggregateFromServer, count, sum,
} from './vendor/firebase-firestore.js';

let auth;
let db;

export function start(config) {
  const app = initializeApp(config);
  auth = getAuth(app);
  db = getFirestore(app);
  if (config.emulator) {
    connectAuthEmulator(auth, `http://${config.emulator}:9099`, { disableWarnings: true });
    connectFirestoreEmulator(db, config.emulator, 8080);
  }
}

// ---- Signing in ----

export const onUser = (fn) => onAuthStateChanged(auth, fn);
export const currentUser = () => auth.currentUser;

export async function signIn(emulatorUser) {
  if (emulatorUser) {
    // The emulator accepts an unsigned token for any account (tests and
    // previews only; never used on the real site).
    const b64 = (o) => btoa(JSON.stringify(o)).replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');
    const now = Math.floor(Date.now() / 1000);
    const token = `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
      iss: 'emulator', sub: 'emulator', uid: emulatorUser.uid, iat: now, exp: now + 3600,
      aud: 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
    })}.`;
    return signInWithCustomToken(auth, token);
  }
  return signInWithPopup(auth, new GoogleAuthProvider());
}
export const logOut = () => signOut(auth);

export async function isAdmin(uid) {
  try {
    return (await getDoc(doc(db, 'admins', uid))).exists();
  } catch {
    return false;
  }
}

// ---- Helpers ----

const ts = (v) => (v instanceof Timestamp ? v.toDate() : null);
const daysAgo = (n) => Timestamp.fromDate(new Date(Date.now() - n * 86400000));
const docs = (snap) => snap.docs.map((d) => ({ id: d.id, ...d.data() }));

async function countOf(q) {
  try {
    return (await getCountFromServer(q)).data().count;
  } catch (e) {
    console.warn('count failed', e);
    return null;
  }
}

// ---- People ----

/** Everyone with a profile, with their application, pause and admin state. */
export async function people() {
  const [users, apps, paused, admins, presence] = await Promise.all([
    getDocs(collection(db, 'users')),
    getDocs(collection(db, 'teacherApplications')),
    getDocs(collection(db, 'suspensions')),
    getDocs(collection(db, 'admins')),
    getDocs(collection(db, 'presence')),
  ]);
  const appOf = new Map(apps.docs.map((d) => [d.id, d.data()]));
  const pausedOf = new Map(paused.docs.map((d) => [d.id, d.data()]));
  const adminIds = new Set(admins.docs.map((d) => d.id));
  const presenceOf = new Map(presence.docs.map((d) => [d.id, d.data()]));
  return users.docs
    .map((d) => {
      const u = d.data();
      const app = appOf.get(d.id);
      const p = pausedOf.get(d.id);
      return {
        uid: d.id,
        name: u.name || '',
        role: u.role || null,
        gender: u.gender || null,
        avatar: u.avatar || null,
        locale: u.locale || null,
        ageGroup: u.ageGroup || null,
        nationality: u.nationality || null,
        phone: u.phone || null,
        whatsapp: u.whatsapp === true,
        joined: ts(u.createdAt),
        lastActive: ts(u.lastActive) || ts(u.updatedAt),
        updatedAt: ts(u.updatedAt),
        appStatus: app ? app.status : null,
        paused: p ? { reason: p.reason || '', at: ts(p.at), by: p.by } : null,
        admin: adminIds.has(d.id),
        available: presenceOf.get(d.id)?.available === true,
      };
    })
    .sort((a, b) => a.name.localeCompare(b.name));
}

export async function setPaused(uid, paused, reason = '') {
  if (!paused) return deleteDoc(doc(db, 'suspensions', uid));
  const b = writeBatch(db);
  b.set(doc(db, 'suspensions', uid), { reason: reason.trim(), by: auth.currentUser.uid, at: serverTimestamp() });
  // No more calls to a paused teacher.
  b.delete(doc(db, 'presence', uid));
  return b.commit();
}

export async function photo(uid) {
  const d = await getDoc(doc(db, 'photos', uid));
  if (!d.exists()) return null;
  return URL.createObjectURL(new Blob([d.data().data.toUint8Array()], { type: 'image/jpeg' }));
}
export const removePhoto = (uid) => deleteDoc(doc(db, 'photos', uid));

// ---- Admins ----

export async function admins() {
  return docs(await getDocs(collection(db, 'admins')));
}
export const addAdmin = (uid, name) =>
  setDoc(doc(db, 'admins', uid), { name: name.slice(0, 80), by: auth.currentUser.uid, at: serverTimestamp() });
export const removeAdmin = (uid) => deleteDoc(doc(db, 'admins', uid));

// ---- Teacher applications ----

export async function applications() {
  return docs(await getDocs(collection(db, 'teacherApplications'))).map((a) => ({
    ...a,
    submitted: ts(a.submittedAt),
    decided: ts(a.decidedAt),
    answers: (a.order || Object.keys(a.answers || {}))
      .filter((k) => a.answers?.[k] != null)
      .map((k) => [k, String(a.answers[k])]),
  }));
}

export async function sample(uid) {
  const d = await getDoc(doc(db, 'applicationSamples', uid));
  if (!d.exists()) return null;
  return URL.createObjectURL(new Blob([d.data().data.toUint8Array()], { type: 'audio/mp4' }));
}

export const decide = (uid, approve, reason = '') =>
  updateDoc(doc(db, 'teacherApplications', uid), {
    status: approve ? 'approved' : 'rejected',
    reason: reason.trim(),
    decidedAt: serverTimestamp(),
    decidedBy: auth.currentUser.uid,
  });

// ---- Lessons, calls, chats ----

const lesson = (s) => ({
  ...s,
  at: ts(s.startedAt) || ts(s.createdAt),
  minutes: Math.round((s.durationSec || 0) / 60),
});

/** Lessons since [days] ago (all of them when days is null), newest first. */
export async function lessons(days) {
  const q = days == null
    ? collection(db, 'sessions')
    : query(collection(db, 'sessions'), where('startedAt', '>=', daysAgo(days)));
  return docs(await getDocs(q)).map(lesson).sort((a, b) => (b.at || 0) - (a.at || 0));
}

export async function lessonsOf(uid) {
  const [a, b] = await Promise.all([
    getDocs(query(collection(db, 'sessions'), where('studentId', '==', uid))),
    getDocs(query(collection(db, 'sessions'), where('teacherId', '==', uid))),
  ]);
  return [...docs(a), ...docs(b)].map(lesson).sort((x, y) => (y.at || 0) - (x.at || 0));
}

/** Calls since [days] ago: who asked, and how each ended. */
export async function calls(days) {
  const snap = await getDocs(query(collection(db, 'calls'), where('createdAt', '>=', daysAgo(days))));
  return snap.docs.map((d) => {
    const c = d.data();
    return {
      id: d.id,
      status: c.status,
      direction: c.direction || 'toTeacher',
      studentId: c.studentId,
      teacherId: c.teacherId || null,
      gender: c.gender,
      at: ts(c.createdAt),
    };
  });
}

/** A person's chats: with whom, when, and how many messages each sent. The
 * messages themselves stay private. */
export async function chatsOf(uid) {
  const snap = await getDocs(query(collection(db, 'conversations'), where('members', 'array-contains', uid)));
  return snap.docs.map((d) => {
    const c = d.data();
    const other = c.members.find((m) => m !== uid);
    return {
      id: d.id,
      other,
      otherName: c.names?.[other] || '',
      started: ts(c.createdAt),
      lastAt: ts(c.lastAt),
      sentByThem: c.sent?.[uid] || 0,
      sentByOther: c.sent?.[other] || 0,
      blocked: (c.blockedBy || []).length > 0,
    };
  });
}

/** Opens a chat between a student and a teacher of the same gender. */
export async function connect(student, teacher) {
  if (!student.gender || student.gender !== teacher.gender) throw new Error('A student and teacher must be of the same gender.');
  const ref = doc(db, 'conversations', `${student.uid}_${teacher.uid}`);
  if ((await getDoc(ref)).exists()) return false;
  await setDoc(ref, {
    members: [student.uid, teacher.uid],
    names: { [student.uid]: student.name, [teacher.uid]: teacher.name },
    avatars: { [student.uid]: student.avatar, [teacher.uid]: teacher.avatar },
    roles: { [student.uid]: 'student', [teacher.uid]: 'teacher' },
    gender: student.gender,
    unread: { [student.uid]: 0, [teacher.uid]: 0 },
    blockedBy: [],
    lastText: '',
    createdBy: auth.currentUser.uid,
    createdAt: serverTimestamp(),
  });
  return true;
}

// ---- Reports ----

export async function reports() {
  return docs(await getDocs(collection(db, 'reports')))
    .map((r) => ({ ...r, at: ts(r.createdAt) }))
    .sort((a, b) => (b.at || 0) - (a.at || 0));
}
export const resolveReport = (id, resolved = true) =>
  updateDoc(doc(db, 'reports', id), { status: resolved ? 'resolved' : 'open', resolvedBy: auth.currentUser.uid });

// ---- Announcements ----

export async function announcements() {
  const snap = await getDocs(query(collection(db, 'announcements'), orderBy('at', 'desc'), limit(100)));
  return docs(snap).map((a) => ({ ...a, at: ts(a.at), until: ts(a.until) }));
}
export const addAnnouncement = ({ textEn, textAr, audience, until }) =>
  addDoc(collection(db, 'announcements'), {
    textEn: textEn.trim(),
    textAr: textAr.trim(),
    audience,
    ...(until ? { until: Timestamp.fromDate(until) } : {}),
    by: auth.currentUser.uid,
    at: serverTimestamp(),
  });
export const removeAnnouncement = (id) => deleteDoc(doc(db, 'announcements', id));

// ---- Live counts ----

export async function liveCounts() {
  const now = Timestamp.now();
  const [teachersOn, waiting, openReports, pending] = await Promise.all([
    countOf(query(collection(db, 'presence'), where('available', '==', true))),
    countOf(query(collection(db, 'waiting'), where('until', '>', now))),
    countOf(query(collection(db, 'reports'), where('status', '==', 'open'))),
    countOf(query(collection(db, 'teacherApplications'), where('status', '==', 'pending'))),
  ]);
  return { teachersOn, waiting, openReports, pending };
}

/** Number of lessons and minutes taught, ever (cheap: counted on the server). */
export async function lessonTotals() {
  try {
    const a = await getAggregateFromServer(collection(db, 'sessions'), { n: count(), secs: sum('durationSec') });
    return { lessons: a.data().n, minutes: Math.round((a.data().secs || 0) / 60) };
  } catch (e) {
    console.warn('totals failed', e);
    return { lessons: null, minutes: null };
  }
}
