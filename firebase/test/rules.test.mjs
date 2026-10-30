// Tests for firestore.rules, run against the Firestore emulator:
//   cd firebase/test && npm install && npm test
import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, collection, getDocs, query, where, addDoc,
  serverTimestamp, increment, arrayUnion, Bytes, Timestamp,
} from 'firebase/firestore';

let env;
const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'sanadi-rules-test',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});
after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (c) => {
    const f = c.firestore();
    await setDoc(doc(f, 'users/s1'), { name: 'Fatima', role: 'student', gender: 'female' });
    await setDoc(doc(f, 'users/s2'), { name: 'Maryam', role: 'student', gender: 'female' });
    await setDoc(doc(f, 'users/t1'), { name: 'Aisha', role: 'teacher', gender: 'female' });
    await setDoc(doc(f, 'users/t2'), { name: 'Yusuf', role: 'teacher', gender: 'male' });
    await setDoc(doc(f, 'users/t3'), { name: 'Khadijah', role: 'teacher', gender: 'female' });
    await setDoc(doc(f, 'users/t9'), { name: 'N', role: 'teacher', gender: 'male' });
    await setDoc(doc(f, 'teacherApplications/t1'), { name: 'Aisha', gender: 'female', status: 'approved', answers: {}, order: [] });
    await setDoc(doc(f, 'teacherApplications/t2'), { name: 'Yusuf', gender: 'male', status: 'approved', answers: {}, order: [] });
    await setDoc(doc(f, 'teacherApplications/t3'), { name: 'Khadijah', gender: 'female', status: 'pending', answers: {}, order: [] });
    await setDoc(doc(f, 'admins/admin1'), { role: 'admin' });
  });
});

const conv = (s, t) => ({
  members: [s, t],
  names: { [s]: 'S', [t]: 'T' },
  avatars: { [s]: null, [t]: null },
  roles: { [s]: 'student', [t]: 'teacher' },
  gender: 'female',
  unread: { [s]: 0, [t]: 0 },
  blockedBy: [],
  lastText: '',
  createdBy: 'admin1',
  createdAt: serverTimestamp(),
});

async function openChat() {
  await assertSucceeds(setDoc(doc(db('admin1'), 'conversations/s1_t1'), conv('s1', 't1')));
}

function sendText(uid, text, sender = uid) {
  const f = db(uid);
  const c = doc(f, 'conversations/s1_t1');
  const m = doc(collection(c, 'messages'));
  const other = uid === 's1' ? 't1' : 's1';
  return writeBatch(f)
    .set(m, { senderId: sender, type: 'text', text, sentAt: serverTimestamp() })
    .update(c, { lastText: text, lastVoiceSec: null, lastSender: uid, lastAt: serverTimestamp(), [`unread.${other}`]: increment(1) })
    .commit()
    .then(() => m.id);
}

function sendVoice(uid, bytes) {
  const f = db(uid);
  const c = doc(f, 'conversations/s1_t1');
  const m = doc(collection(c, 'messages'));
  return writeBatch(f)
    .set(doc(c, 'audio', m.id), { senderId: uid, data: Bytes.fromUint8Array(new Uint8Array(bytes)), createdAt: serverTimestamp() })
    .set(m, { senderId: uid, type: 'voice', durationSec: 42, sentAt: serverTimestamp() })
    .update(c, { lastText: '', lastVoiceSec: 42, lastSender: uid, lastAt: serverTimestamp(), 'unread.t1': increment(1) })
    .commit()
    .then(() => m.id);
}

// ---- Existing parts still behave ----

test('profiles: own only', async () => {
  await assertSucceeds(setDoc(doc(db('s1'), 'users/s1'), { name: 'F', role: 'student', gender: 'female', avatar: null, locale: 'ar', updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(db('s1'), 'users/s2')));
  await assertFails(setDoc(doc(db('s1'), 'users/s2'), { name: 'x' }));
  await assertSucceeds(getDoc(doc(db('admin1'), 'users/s2')));
});

test('applications: send, cannot self-approve, admin decides', async () => {
  await assertSucceeds(setDoc(doc(db('t9'), 'teacherApplications/t9'), { name: 'N', gender: 'male', answers: {}, order: [], status: 'pending', submittedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db('t9'), 'teacherApplications/t9'), { status: 'approved' }));
  await assertSucceeds(updateDoc(doc(db('admin1'), 'teacherApplications/t9'), { status: 'approved', reason: '', decidedAt: serverTimestamp(), decidedBy: 'admin1' }));
});

test('presence: only approved teachers', async () => {
  await assertSucceeds(setDoc(doc(db('t1'), 'presence/t1'), { available: true, gender: 'female', updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('t3'), 'presence/t3'), { available: true, gender: 'female', updatedAt: serverTimestamp() }));
  await assertSucceeds(getDocs(query(collection(db('s1'), 'presence'), where('available', '==', true), where('gender', '==', 'female'))));
  await assertFails(getDocs(query(collection(db('s1'), 'presence'), where('available', '==', true))));
  await assertFails(getDoc(doc(db(null), 'presence/t1')));
});

// ---- Chat ----

test('only an admin opens a chat, same gender, approved teacher', async () => {
  await assertFails(setDoc(doc(db('s1'), 'conversations/s1_t1'), conv('s1', 't1')));
  await assertFails(setDoc(doc(db('admin1'), 'conversations/s1_t2'), { ...conv('s1', 't2') }));
  await assertFails(setDoc(doc(db('admin1'), 'conversations/s1_t3'), conv('s1', 't3')));
  await assertFails(setDoc(doc(db('admin1'), 'conversations/wrong_id'), conv('s1', 't1')));
  await openChat();
});

test('only the two members read the chat', async () => {
  await openChat();
  await assertSucceeds(getDoc(doc(db('s1'), 'conversations/s1_t1')));
  await assertSucceeds(getDoc(doc(db('t1'), 'conversations/s1_t1')));
  await assertFails(getDoc(doc(db('s2'), 'conversations/s1_t1')));
  await assertSucceeds(getDocs(query(collection(db('s1'), 'conversations'), where('members', 'array-contains', 's1'))));
  await assertFails(getDocs(collection(db('s2'), 'conversations/s1_t1/messages')));
});

test('text messages', async () => {
  await openChat();
  await assertSucceeds(sendText('s1', 'As-salamu alaykum'));
  await assertSucceeds(sendText('t1', 'Wa alaykum as-salam'));
  await assertSucceeds(getDocs(collection(db('t1'), 'conversations/s1_t1/messages')));
  await assertFails(sendText('s1', 'pretending', 't1'));
  await assertFails(sendText('s1', 'x'.repeat(2001)));
  await assertFails(sendText('s1', ''));
  await assertFails(sendText('s2', 'not a member'));
});

test('voice notes', async () => {
  await openChat();
  const id = await assertSucceeds(sendVoice('s1', new Array(300000).fill(7)));
  await assertSucceeds(getDoc(doc(db('t1'), `conversations/s1_t1/audio/${id}`)));
  await assertFails(getDoc(doc(db('s2'), `conversations/s1_t1/audio/${id}`)));
  await assertFails(sendVoice('s1', new Array(950000).fill(7)));
});

test('read receipts and own name', async () => {
  await openChat();
  await sendText('s1', 'hi');
  await assertSucceeds(updateDoc(doc(db('t1'), 'conversations/s1_t1'), { 'unread.t1': 0 }));
  await assertSucceeds(updateDoc(doc(db('t1'), 'conversations/s1_t1'), { 'names.t1': 'Aisha R', 'avatars.t1': 'ft2' }));
  await assertFails(updateDoc(doc(db('t1'), 'conversations/s1_t1'), { members: ['s2', 't1'] }));
  await assertFails(updateDoc(doc(db('t1'), 'conversations/s1_t1'), { gender: 'male' }));
  await assertFails(updateDoc(doc(db('s2'), 'conversations/s1_t1'), { 'unread.s2': 0 }));
});

test('delete: only your own messages', async () => {
  await openChat();
  const mine = await sendText('s1', 'mine');
  const voice = await sendVoice('s1', [1, 2, 3]);
  const theirs = await sendText('t1', 'theirs');
  await assertFails(deleteDoc(doc(db('s1'), `conversations/s1_t1/messages/${theirs}`)));
  await assertSucceeds(deleteDoc(doc(db('s1'), `conversations/s1_t1/messages/${mine}`)));
  const f = db('s1');
  await assertSucceeds(writeBatch(f)
    .delete(doc(f, `conversations/s1_t1/messages/${voice}`))
    .delete(doc(f, `conversations/s1_t1/audio/${voice}`))
    .commit());
});

test('block stops both from sending; each controls only their own block', async () => {
  await openChat();
  await assertFails(updateDoc(doc(db('t1'), 'conversations/s1_t1'), { blockedBy: ['s1'] }));
  await assertSucceeds(updateDoc(doc(db('t1'), 'conversations/s1_t1'), { blockedBy: arrayUnion('t1') }));
  await assertFails(sendText('s1', 'blocked'));
  await assertFails(sendText('t1', 'blocked'));
  await assertFails(updateDoc(doc(db('s1'), 'conversations/s1_t1'), { blockedBy: [] }));
  await assertSucceeds(updateDoc(doc(db('t1'), 'conversations/s1_t1'), { blockedBy: [] }));
  await assertSucceeds(sendText('s1', 'unblocked'));
});

test('reports: anyone signed in sends, only admins read', async () => {
  await openChat();
  const r = { reporterId: 's1', reporterName: 'F', reportedId: 't1', reportedName: 'A', conversationId: 's1_t1', reason: 'words', details: '', status: 'open', createdAt: serverTimestamp() };
  await assertSucceeds(addDoc(collection(db('s1'), 'reports'), r));
  await assertFails(addDoc(collection(db('s1'), 'reports'), { ...r, reporterId: 's2' }));
  // Only about the other member of your own chat, with a known reason.
  await assertFails(addDoc(collection(db('s1'), 'reports'), { ...r, reportedId: 's1' }));
  await assertFails(addDoc(collection(db('s1'), 'reports'), { ...r, reportedId: 't2' }));
  await assertFails(addDoc(collection(db('s2'), 'reports'), { ...r, reporterId: 's2' }));
  await assertFails(addDoc(collection(db('s1'), 'reports'), { ...r, reason: 'anything' }));
  await assertFails(getDocs(collection(db('s1'), 'reports')));
  await assertSucceeds(getDocs(query(collection(db('admin1'), 'reports'), where('status', '==', 'open'))));
});

// ---- Calls ----

async function startCall(uid = 's1', gender = 'female') {
  const ref = doc(collection(db(uid), 'calls'));
  await setDoc(ref, { studentId: uid, studentName: 'F', studentAvatar: null, gender, status: 'searching', teacherId: null, tried: [], createdAt: serverTimestamp() });
  return ref.id;
}

test('calls: a student starts one, with their own gender', async () => {
  await assertSucceeds(startCall('s1', 'female'));
  await assertFails(startCall('s1', 'male'));
  await assertFails(startCall('t1', 'female')); // teachers don't start calls
});

test('calls: ring only approved teachers of the same gender', async () => {
  const id = await startCall();
  const ring = (t) => updateDoc(doc(db('s1'), `calls/${id}`), { teacherId: t, status: 'ringing', tried: arrayUnion(t), ringAt: serverTimestamp() });
  await assertFails(ring('t2')); // male
  await assertFails(ring('t3')); // not approved
  await assertSucceeds(ring('t1'));
  await assertFails(updateDoc(doc(db('s1'), `calls/${id}`), { status: 'active' })); // only the teacher accepts
});

test('calls: only the student and the teacher being rung can see it', async () => {
  const id = await startCall();
  await assertFails(getDoc(doc(db('t1'), `calls/${id}`)));
  await updateDoc(doc(db('s1'), `calls/${id}`), { teacherId: 't1', status: 'ringing' });
  await assertSucceeds(getDoc(doc(db('t1'), `calls/${id}`)));
  await assertSucceeds(getDocs(query(collection(db('t1'), 'calls'), where('teacherId', '==', 't1'), where('status', '==', 'ringing'))));
  await assertFails(getDoc(doc(db('s2'), `calls/${id}`)));
  await assertFails(getDoc(doc(db('t3'), `calls/${id}`)));
});

test('calls: answer, connect, hang up; then the chat opens', async () => {
  const id = await startCall();
  await updateDoc(doc(db('s1'), `calls/${id}`), { teacherId: 't1', status: 'ringing' });
  await assertSucceeds(updateDoc(doc(db('t1'), `calls/${id}`), { status: 'active', teacherName: 'A', teacherAvatar: null, acceptedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(db('s1'), `calls/${id}`), { offer: { type: 'offer', sdp: 'x' } }));
  await assertSucceeds(updateDoc(doc(db('t1'), `calls/${id}`), { answer: { type: 'answer', sdp: 'y' } }));
  await assertFails(updateDoc(doc(db('t1'), `calls/${id}`), { offer: { type: 'offer', sdp: 'z' } }));
  await assertSucceeds(addDoc(collection(db('s1'), `calls/${id}/ice`), { from: 'student', senderId: 's1', c: {} }));
  await assertFails(addDoc(collection(db('s1'), `calls/${id}/ice`), { from: 'teacher', senderId: 's1', c: {} }));
  await assertSucceeds(addDoc(collection(db('t1'), `calls/${id}/ice`), { from: 'teacher', senderId: 't1', c: {} }));
  await assertSucceeds(getDocs(query(collection(db('t1'), `calls/${id}/ice`), where('from', '==', 'student'))));
  await assertFails(getDocs(collection(db('s2'), `calls/${id}/ice`)));
  await assertSucceeds(updateDoc(doc(db('t1'), `calls/${id}`), { status: 'ended', endedAt: serverTimestamp() }));

  const chat = { ...conv('s1', 't1'), fromCall: id, createdBy: 's1' };
  await assertFails(setDoc(doc(db('t1'), 'conversations/s1_t1'), chat)); // the student opens it
  await assertFails(setDoc(doc(db('s1'), 'conversations/s1_t3'), { ...conv('s1', 't3'), fromCall: id }));
  await assertSucceeds(setDoc(doc(db('s1'), 'conversations/s1_t1'), chat));
  await assertSucceeds(sendText('s1', 'JazakAllahu khayran'));
});

test('calls: a teacher declines; an old teacher can no longer change it', async () => {
  const id = await startCall();
  await updateDoc(doc(db('s1'), `calls/${id}`), { teacherId: 't1', status: 'ringing' });
  await assertSucceeds(updateDoc(doc(db('t1'), `calls/${id}`), { status: 'declined' }));
  await assertFails(updateDoc(doc(db('t1'), `calls/${id}`), { status: 'active' }));
});

test('presence: busy flag', async () => {
  await assertSucceeds(setDoc(doc(db('t1'), 'presence/t1'), { available: true, gender: 'female', updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(db('t1'), 'presence/t1'), { busy: true, updatedAt: serverTimestamp() }));
});

// ---- Lessons ----

async function endedCall() {
  const id = await startCall();
  await updateDoc(doc(db('s1'), `calls/${id}`), { teacherId: 't1', status: 'ringing' });
  await updateDoc(doc(db('t1'), `calls/${id}`), { status: 'active' });
  await updateDoc(doc(db('t1'), `calls/${id}`), { status: 'ended' });
  return id;
}

const lesson = (over = {}) => ({
  studentId: 's1', teacherId: 't1', studentName: 'F', teacherName: 'A', studentAvatar: null, teacherAvatar: null,
  gender: 'female', startedAt: new Date(), durationSec: 600, createdAt: serverTimestamp(), ...over,
});

test('lessons: saved by either person for their own call only', async () => {
  const id = await endedCall();
  await assertFails(setDoc(doc(db('s2'), `sessions/${id}`), lesson({ studentId: 's2' })));
  await assertFails(setDoc(doc(db('s1'), `sessions/${id}`), lesson({ teacherId: 't3' })));
  await assertFails(setDoc(doc(db('s1'), `sessions/not-a-call`), lesson()));
  await assertSucceeds(setDoc(doc(db('t1'), `sessions/${id}`), lesson()));
  await assertSucceeds(getDoc(doc(db('s1'), `sessions/${id}`)));
  await assertFails(getDoc(doc(db('s2'), `sessions/${id}`)));
  await assertSucceeds(getDocs(query(collection(db('s1'), 'sessions'), where('studentId', '==', 's1'))));
  await assertSucceeds(getDocs(query(collection(db('t1'), 'sessions'), where('teacherId', '==', 't1'))));
});

test('lessons: only the teacher writes notes, only the student rates', async () => {
  const id = await endedCall();
  await setDoc(doc(db('s1'), `sessions/${id}`), lesson());
  const notes = { recited: { sura: 67, from: 1, to: 10 }, grade: 1, practise: [3, 7], next: { sura: 67, from: 11, to: 20 }, note: 'Well done', at: serverTimestamp() };
  await assertFails(updateDoc(doc(db('s1'), `sessions/${id}`), { notes }));
  await assertSucceeds(updateDoc(doc(db('t1'), `sessions/${id}`), { notes }));
  await assertFails(updateDoc(doc(db('t1'), `sessions/${id}`), { notes: { ...notes, grade: 5 } }));
  await assertFails(updateDoc(doc(db('t1'), `sessions/${id}`), { notes: { ...notes, recited: { sura: 200, from: 1, to: 2 } } }));
  await assertFails(updateDoc(doc(db('t1'), `sessions/${id}`), { durationSec: 9999 }));
  await assertSucceeds(updateDoc(doc(db('s1'), `sessions/${id}`), { rating: 2 }));
  await assertFails(updateDoc(doc(db('t1'), `sessions/${id}`), { rating: 0 }));
  await assertFails(updateDoc(doc(db('s1'), `sessions/${id}`), { rating: 7 }));
});

test('application samples: own only, admins listen, size limit', async () => {
  const sample = { data: Bytes.fromUint8Array(new Uint8Array(1000)), durationSec: 60, createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(doc(db('t3'), 'applicationSamples/t3'), sample));
  await assertFails(setDoc(doc(db('t3'), 'applicationSamples/t1'), sample));
  await assertFails(setDoc(doc(db('t3'), 'applicationSamples/t3'), { ...sample, data: Bytes.fromUint8Array(new Uint8Array(900001)) }));
  await assertFails(setDoc(doc(db('t3'), 'applicationSamples/t3'), { ...sample, extra: 1 }));
  await assertSucceeds(getDoc(doc(db('t3'), 'applicationSamples/t3')));
  await assertSucceeds(getDoc(doc(db('admin1'), 'applicationSamples/t3')));
  await assertFails(getDoc(doc(db('t1'), 'applicationSamples/t3')));
  await assertFails(getDoc(doc(db('s1'), 'applicationSamples/t3')));
  // The application says how long the sample is.
  await assertSucceeds(setDoc(doc(db('t3'), 'teacherApplications/t3'), {
    name: 'Khadijah', gender: 'female', answers: {}, order: [], sampleSec: 60, status: 'pending', submittedAt: serverTimestamp(),
  }));
});

test('delete account: own profile, application and sample only', async () => {
  await env.withSecurityRulesDisabled(async (c) => {
    await setDoc(doc(c.firestore(), 'applicationSamples/t3'), { data: Bytes.fromUint8Array(new Uint8Array(10)), durationSec: 5 });
  });
  await assertFails(deleteDoc(doc(db('t1'), 'applicationSamples/t3')));
  await assertFails(deleteDoc(doc(db('t1'), 'teacherApplications/t3')));
  await assertFails(deleteDoc(doc(db('t1'), 'users/t3')));
  await assertSucceeds(deleteDoc(doc(db('t3'), 'applicationSamples/t3')));
  await assertSucceeds(deleteDoc(doc(db('t3'), 'teacherApplications/t3')));
  await assertSucceeds(deleteDoc(doc(db('t3'), 'users/t3')));
});

test('reports: an admin marks one as dealt with', async () => {
  await openChat();
  const r = doc(collection(db('s1'), 'reports'));
  await assertSucceeds(setDoc(r, {
    reporterId: 's1', reporterName: 'F', reportedId: 't1', reportedName: 'A', conversationId: 's1_t1',
    reason: 'other', details: '', status: 'open', createdAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(db('s1'), `reports/${r.id}`), { status: 'resolved' }));
  await assertSucceeds(updateDoc(doc(db('admin1'), `reports/${r.id}`), { status: 'resolved', resolvedBy: 'admin1' }));
  // Even an admin can't rewrite what was reported.
  await assertFails(updateDoc(doc(db('admin1'), `reports/${r.id}`), { details: 'changed' }));
});

// ---- Hardening ----

test('profile: gender is chosen once; picture and language are checked', async () => {
  await assertSucceeds(setDoc(doc(db('new1'), 'users/new1'), { name: 'A', role: 'student' }));
  await assertSucceeds(updateDoc(doc(db('new1'), 'users/new1'), { gender: 'male' }));
  await assertFails(updateDoc(doc(db('new1'), 'users/new1'), { gender: 'female' }));
  await assertSucceeds(updateDoc(doc(db('new1'), 'users/new1'), { name: 'B', gender: 'male' }));
  await assertFails(updateDoc(doc(db('s1'), 'users/s1'), { gender: 'male' }));
  await assertFails(updateDoc(doc(db('s1'), 'users/s1'), { avatar: 'x'.repeat(21) }));
  await assertFails(updateDoc(doc(db('s1'), 'users/s1'), { locale: 'fr' }));
  await assertFails(updateDoc(doc(db('s1'), 'users/s1'), { name: 'x'.repeat(81) }));
});

test('applications: the gender must match the profile; the reason is limited', async () => {
  const app = { name: 'N', gender: 'female', answers: {}, order: [], status: 'pending', submittedAt: serverTimestamp() };
  await assertFails(setDoc(doc(db('t9'), 'teacherApplications/t9'), app));
  await assertSucceeds(setDoc(doc(db('t9'), 'teacherApplications/t9'), { ...app, gender: 'male' }));
  await assertFails(updateDoc(doc(db('admin1'), 'teacherApplications/t9'), {
    status: 'rejected', reason: 'x'.repeat(1001), decidedAt: serverTimestamp(), decidedBy: 'admin1',
  }));
  await assertFails(updateDoc(doc(db('admin1'), 'teacherApplications/t9'), {
    status: 'approved', reason: '', decidedAt: serverTimestamp(), decidedBy: 'someone-else',
  }));
});

test('a teacher is matched by the gender on their approved application', async () => {
  // Changing the profile can't move a teacher to the other gender.
  await env.withSecurityRulesDisabled(async (c) => {
    await setDoc(doc(c.firestore(), 'users/t2'), { name: 'Yusuf', role: 'teacher', gender: 'female' });
  });
  await assertFails(setDoc(doc(db('t2'), 'presence/t2'), { available: true, gender: 'female', updatedAt: serverTimestamp() }));
  await assertSucceeds(setDoc(doc(db('t2'), 'presence/t2'), { available: true, gender: 'male', updatedAt: serverTimestamp() }));
  const id = await startCall('s1', 'female');
  await assertFails(updateDoc(doc(db('s1'), `calls/${id}`), { status: 'ringing', teacherId: 't2', tried: ['t2'] }));
  await assertFails(setDoc(doc(db('admin1'), 'conversations/s1_t2'), conv('s1', 't2')));
});

test('chat: a member changes only their own name and picture', async () => {
  await openChat();
  await assertSucceeds(updateDoc(doc(db('s1'), 'conversations/s1_t1'), { 'names.s1': 'Fatima Z', 'avatars.s1': 'fs1' }));
  await assertFails(updateDoc(doc(db('s1'), 'conversations/s1_t1'), { 'names.t1': 'Someone else' }));
  await assertFails(updateDoc(doc(db('s1'), 'conversations/s1_t1'), { 'avatars.t1': 'fs1' }));
  await assertFails(updateDoc(doc(db('s1'), 'conversations/s1_t1'), { 'names.s1': 'x'.repeat(81) }));
});

// ---- Pausing accounts ----

test('only admins pause and restore; the person can see it', async () => {
  const pause = { reason: 'Rude messages', by: 'admin1', at: serverTimestamp() };
  await assertFails(setDoc(doc(db('s1'), 'suspensions/s2'), { ...pause, by: 's1' }));
  await assertFails(setDoc(doc(db('admin1'), 'suspensions/s2'), { ...pause, by: 'someone' }));
  await assertSucceeds(setDoc(doc(db('admin1'), 'suspensions/s2'), pause));
  await assertSucceeds(getDoc(doc(db('s2'), 'suspensions/s2')));
  await assertFails(getDoc(doc(db('s1'), 'suspensions/s2')));
  await assertFails(deleteDoc(doc(db('s2'), 'suspensions/s2')));
  await assertSucceeds(deleteDoc(doc(db('admin1'), 'suspensions/s2')));
  // An admin removes a paused teacher from the available list.
  await env.withSecurityRulesDisabled(async (c) => {
    await setDoc(doc(c.firestore(), 'presence/t1'), { available: true, gender: 'female' });
  });
  await assertFails(deleteDoc(doc(db('s1'), 'presence/t1')));
  await assertSucceeds(deleteDoc(doc(db('admin1'), 'presence/t1')));
});

test('a paused person cannot message, call, teach or apply', async () => {
  await openChat();
  await env.withSecurityRulesDisabled(async (c) => {
    await setDoc(doc(c.firestore(), 'suspensions/s1'), { reason: '', by: 'admin1' });
    await setDoc(doc(c.firestore(), 'suspensions/t1'), { reason: '', by: 'admin1' });
  });
  await assertFails(sendText('s1', 'hello'));
  await assertFails(startCall('s1', 'female'));
  await assertFails(setDoc(doc(db('t1'), 'presence/t1'), { available: true, gender: 'female', updatedAt: serverTimestamp() }));
  // Nobody can ring a paused teacher.
  const id = await startCall('s2', 'female');
  await assertFails(updateDoc(doc(db('s2'), `calls/${id}`), { status: 'ringing', teacherId: 't1', tried: ['t1'] }));
  await env.withSecurityRulesDisabled(async (c) => setDoc(doc(c.firestore(), 'suspensions/t3'), { reason: '', by: 'admin1' }));
  await assertFails(setDoc(doc(db('t3'), 'teacherApplications/t3'), {
    name: 'K', gender: 'female', answers: {}, order: [], status: 'pending', submittedAt: serverTimestamp(),
  }));
  // Restored: everything works again.
  await env.withSecurityRulesDisabled(async (c) => deleteDoc(doc(c.firestore(), 'suspensions/s1')));
  await assertSucceeds(sendText('s1', 'hello again'));
});

test('admins can read lessons for the overview', async () => {
  await env.withSecurityRulesDisabled(async (c) => {
    await setDoc(doc(c.firestore(), 'sessions/x1'), { studentId: 's1', teacherId: 't1', durationSec: 600 });
  });
  await assertSucceeds(getDocs(collection(db('admin1'), 'sessions')));
  await assertFails(getDocs(collection(db('s2'), 'sessions')));
});

// ---- Teacher list and waiting students ----

test('students see the teachers of their own gender only, with name and picture', async () => {
  await assertSucceeds(setDoc(doc(db('t1'), 'presence/t1'), {
    available: true, gender: 'female', name: 'Aisha', avatar: 'ft2', updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(setDoc(doc(db('t2'), 'presence/t2'), {
    available: true, gender: 'male', name: 'Yusuf', avatar: 'mt1', updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db('t1'), 'presence/t1'), { available: true, gender: 'female', name: 'x'.repeat(81) }));
  await assertFails(setDoc(doc(db('t1'), 'presence/t1'), { available: true, gender: 'female', phone: '123' }));
  await assertSucceeds(getDocs(query(collection(db('s1'), 'presence'), where('gender', '==', 'female'))));
  await assertFails(getDocs(query(collection(db('s1'), 'presence'), where('gender', '==', 'male'))));
  await assertFails(getDocs(collection(db('s1'), 'presence')));
  await assertSucceeds(getDoc(doc(db('s1'), 'presence/t1')));
  await assertFails(getDoc(doc(db('s1'), 'presence/t2')));
  // A teacher with no entry yet reads as "not there", not as an error.
  await assertSucceeds(getDoc(doc(db('s1'), 'presence/t3')));
  await assertSucceeds(getDocs(collection(db('admin1'), 'presence')));
});

test('waiting: a student waits up to an hour; teachers of that gender see it', async () => {
  const soon = new Date(Date.now() + 60 * 60 * 1000);
  const tooLong = new Date(Date.now() + 3 * 60 * 60 * 1000);
  await assertSucceeds(setDoc(doc(db('s1'), 'waiting/s1'), { gender: 'female', until: soon }));
  await assertFails(setDoc(doc(db('s1'), 'waiting/s1'), { gender: 'female', until: tooLong }));
  await assertFails(setDoc(doc(db('s1'), 'waiting/s1'), { gender: 'male', until: soon }));
  await assertFails(setDoc(doc(db('s1'), 'waiting/s2'), { gender: 'female', until: soon }));
  await assertSucceeds(getDocs(query(collection(db('t1'), 'waiting'), where('gender', '==', 'female'))));
  await assertFails(getDocs(query(collection(db('t2'), 'waiting'), where('gender', '==', 'female'))));
  await assertFails(getDocs(query(collection(db('s2'), 'waiting'), where('gender', '==', 'female'))));
  await assertFails(getDocs(query(collection(db('t3'), 'waiting'), where('gender', '==', 'female'))));
  await assertSucceeds(deleteDoc(doc(db('s1'), 'waiting/s1')));
});

// ---- Sign-up details, own photos, sharing out calls ----

test('profile: age group, nationality, phone and WhatsApp are checked', async () => {
  const me = doc(db('s1'), 'users/s1');
  const base = { name: 'Fatima', role: 'student', gender: 'female' };
  await assertSucceeds(setDoc(me, { ...base, ageGroup: '25-34', nationality: 'SA', phone: '+966512345678', whatsapp: true }));
  await assertFails(setDoc(me, { ...base, ageGroup: '12-17' }));
  await assertFails(setDoc(me, { ...base, nationality: 'Saudi' }));
  await assertFails(setDoc(me, { ...base, phone: '0512345678' }));
  await assertFails(setDoc(me, { ...base, phone: '+966 512 345' }));
  await assertFails(setDoc(me, { ...base, phone: '+1234567890123456' }));
  await assertFails(setDoc(me, { ...base, whatsapp: 'yes' }));
  await assertFails(setDoc(me, { ...base, email: 'x@y.z' }));
  // The phone number is private: other users can't read the profile.
  await assertFails(getDoc(doc(db('t1'), 'users/s1')));
  await assertSucceeds(getDoc(doc(db('admin1'), 'users/s1')));
});

test('profile: the picture is a drawn avatar or the person\'s own photo', async () => {
  const me = doc(db('s1'), 'users/s1');
  const base = { name: 'Fatima', role: 'student', gender: 'female' };
  await assertSucceeds(setDoc(me, { ...base, avatar: 'fs2' }));
  await assertSucceeds(setDoc(me, { ...base, avatar: 'photo:s1:lq3k2j1a' }));
  await assertFails(setDoc(me, { ...base, avatar: 'photo:s2:lq3k2j1a' })); // someone else's
  await assertFails(setDoc(me, { ...base, avatar: 'photo:s1' }));
  await assertFails(setDoc(me, { ...base, avatar: 'x'.repeat(21) }));
  // Calls and the teacher list carry the same picture.
  const call = doc(collection(db('s1'), 'calls'));
  const c = { studentId: 's1', studentName: 'F', gender: 'female', status: 'searching', teacherId: null, tried: [], createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(call, { ...c, studentAvatar: 'photo:s1:abc' }));
  await assertFails(setDoc(doc(collection(db('s1'), 'calls')), { ...c, studentAvatar: 'photo:t1:abc' }));
  await assertSucceeds(setDoc(doc(db('t1'), 'presence/t1'), { available: true, gender: 'female', avatar: 'photo:t1:abc', updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('t1'), 'presence/t1'), { available: true, gender: 'female', avatar: 'photo:t2:abc', updatedAt: serverTimestamp() }));
});

test('photos: the owner saves a small one; the same gender and admins see it', async () => {
  const small = Bytes.fromUint8Array(new Uint8Array(40000));
  const big = Bytes.fromUint8Array(new Uint8Array(150001));
  await assertSucceeds(setDoc(doc(db('s1'), 'photos/s1'), { data: small, updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('s1'), 'photos/s1'), { data: big, updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('s1'), 'photos/s1'), { data: 'not bytes', updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('s1'), 'photos/s1'), { data: small, caption: 'hi' }));
  await assertFails(setDoc(doc(db('s2'), 'photos/s1'), { data: small }));
  await assertSucceeds(getDoc(doc(db('t1'), 'photos/s1'))); // same gender
  await assertFails(getDoc(doc(db('t2'), 'photos/s1'))); // other gender
  await assertFails(getDoc(doc(db(null), 'photos/s1')));
  await assertSucceeds(getDoc(doc(db('admin1'), 'photos/s1')));
  await assertFails(deleteDoc(doc(db('t1'), 'photos/s1')));
  await assertSucceeds(deleteDoc(doc(db('admin1'), 'photos/s1'))); // moderation
  // A paused person can't put up a new photo.
  await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), 'suspensions/s2'), { reason: '', by: 'admin1', at: new Date() }));
  await assertFails(setDoc(doc(db('s2'), 'photos/s2'), { data: small, updatedAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(doc(db('s1'), 'photos/s1')));
});

test('presence: today\'s lesson count, for sharing out calls', async () => {
  const p = doc(db('t1'), 'presence/t1');
  await assertSucceeds(setDoc(p, { available: true, gender: 'female', updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(p, { lessonsToday: 3, lessonsDay: '2026-10-15' }));
  await assertFails(updateDoc(p, { lessonsToday: -1 }));
  await assertFails(updateDoc(p, { lessonsToday: 'many' }));
  await assertFails(updateDoc(p, { lessonsDay: 'x'.repeat(11) }));
});

// ---- A teacher calls their own student ----

function teacherCall(teacher = 't1', student = 's1', extra = {}) {
  const ref = doc(collection(db(teacher), 'calls'));
  return setDoc(ref, {
    studentId: student, studentName: 'F', studentAvatar: null, teacherId: teacher, teacherName: 'T', teacherAvatar: null,
    gender: 'female', status: 'ringing', direction: 'toStudent', tried: [], createdAt: serverTimestamp(), ...extra,
  }).then(() => ref.id);
}

test('a teacher rings only a student they share a chat with', async () => {
  await assertFails(teacherCall('t1', 's1')); // no chat yet
  await openChat();
  await assertSucceeds(teacherCall('t1', 's1'));
  await assertFails(teacherCall('t1', 's2')); // not their student
  await assertFails(teacherCall('t3', 's1')); // not approved
  await assertFails(teacherCall('t2', 's1', { gender: 'male' })); // other gender
  await assertFails(teacherCall('t1', 's1', { status: 'active' })); // can't skip the ringing
  await assertFails(teacherCall('t1', 's1', { teacherId: 't3' })); // only as themself
  await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), 'suspensions/s1'), { reason: '', by: 'admin1', at: new Date() }));
  await assertFails(teacherCall('t1', 's1')); // a paused student can't be rung
});

test('the student answers or declines a call from their teacher; the teacher can give up', async () => {
  await openChat();
  const id = await teacherCall();
  const asStudent = doc(db('s1'), `calls/${id}`);
  const asTeacher = doc(db('t1'), `calls/${id}`);
  await assertSucceeds(getDocs(query(collection(db('s1'), 'calls'), where('studentId', '==', 's1'),
    where('direction', '==', 'toStudent'), where('status', '==', 'ringing'))));
  await assertFails(updateDoc(asTeacher, { status: 'active' })); // only the student answers
  await assertFails(updateDoc(asStudent, { teacherId: 't3' })); // can't put someone else through
  await assertSucceeds(updateDoc(asStudent, { status: 'active' }));
  await assertSucceeds(updateDoc(asStudent, { offer: { type: 'offer', sdp: 'x' } }));
  await assertSucceeds(updateDoc(asTeacher, { answer: { type: 'answer', sdp: 'y' } }));
  await assertSucceeds(updateDoc(asTeacher, { status: 'ended' }));

  const id2 = await teacherCall();
  await assertSucceeds(updateDoc(doc(db('s1'), `calls/${id2}`), { status: 'declined' }));
  const id3 = await teacherCall();
  await assertSucceeds(updateDoc(doc(db('t1'), `calls/${id3}`), { status: 'unmatched' }));
  await assertFails(getDoc(doc(db('s2'), `calls/${id3}`)));
  // A call the student started still can't be answered by the student.
  const own = await startCall();
  await assertFails(updateDoc(doc(db('s1'), `calls/${own}`), { status: 'active' }));
});

// ---- Admin portal ----

test('profile: joined and last-active times are server stamps; joined is set once', async () => {
  const me = doc(db('s1'), 'users/s1');
  await assertSucceeds(setDoc(me, { lastActive: serverTimestamp(), createdAt: serverTimestamp() }, { merge: true }));
  // Not a made-up time.
  await assertFails(setDoc(me, { lastActive: Timestamp.fromDate(new Date(2020, 0, 1)) }, { merge: true }));
  // Joined can't move once set; last active can.
  await assertFails(setDoc(me, { createdAt: serverTimestamp() }, { merge: true }));
  await assertSucceeds(setDoc(me, { lastActive: serverTimestamp() }, { merge: true }));
  // Saving the profile leaves both as they were.
  await assertSucceeds(setDoc(me, { name: 'Fatima A' }, { merge: true }));
});

test('chat: each member counts only their own sent messages', async () => {
  await openChat();
  const c = (uid) => doc(db(uid), 'conversations/s1_t1');
  await assertSucceeds(updateDoc(c('s1'), { 'sent.s1': increment(1), lastSender: 's1' }));
  await assertFails(updateDoc(c('s1'), { 'sent.t1': increment(1) }));
  await assertFails(updateDoc(c('s2'), { 'sent.s2': increment(1) }));
});

test('admins can read calls, for the overview', async () => {
  const id = await startCall();
  await assertSucceeds(getDoc(doc(db('admin1'), `calls/${id}`)));
  await assertSucceeds(getDocs(query(collection(db('admin1'), 'calls'), where('status', '==', 'searching'))));
  await assertFails(getDocs(query(collection(db('s2'), 'calls'), where('status', '==', 'searching'))));
});

test('admins add and remove other admins, never themselves', async () => {
  const add = (by, uid, extra = {}) =>
    setDoc(doc(db(by), `admins/${uid}`), { name: 'Aisha', by, at: serverTimestamp(), ...extra });
  await assertFails(add('s1', 's1'));
  await assertFails(add('admin1', 'nobody'));
  await assertFails(add('admin1', 't1', { by: 's1' }));
  await assertSucceeds(add('admin1', 't1'));
  await assertSucceeds(getDocs(collection(db('t1'), 'admins')));
  await assertFails(getDocs(collection(db('s1'), 'admins')));
  await assertFails(deleteDoc(doc(db('t1'), 'admins/t1')));
  await assertSucceeds(deleteDoc(doc(db('admin1'), 'admins/t1')));
  await assertFails(deleteDoc(doc(db('s1'), 'admins/admin1')));
});

test('announcements: admins write, everyone signed in reads', async () => {
  const a = (by, extra = {}) =>
    addDoc(collection(db(by), 'announcements'), { textEn: 'Hello', textAr: 'مرحبا', audience: 'all', by, at: serverTimestamp(), ...extra });
  await assertFails(a('s1'));
  await assertFails(a('admin1', { audience: 'everyone' }));
  await assertFails(a('admin1', { textEn: '', textAr: '' }));
  await assertFails(a('admin1', { textEn: 'x'.repeat(501) }));
  const ref = await assertSucceeds(a('admin1', { audience: 'teacher', until: Timestamp.fromDate(new Date(2099, 0, 1)) }));
  await assertSucceeds(getDocs(collection(db('s1'), 'announcements')));
  await assertFails(getDocs(collection(db(null), 'announcements')));
  await assertFails(updateDoc(doc(db('admin1'), `announcements/${ref.id}`), { textEn: 'Bye' }));
  await assertFails(deleteDoc(doc(db('s1'), `announcements/${ref.id}`)));
  await assertSucceeds(deleteDoc(doc(db('admin1'), `announcements/${ref.id}`)));
});
