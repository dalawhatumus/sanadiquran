// Tests for firestore.rules, run against the Firestore emulator:
//   cd firebase/test && npm install && npm test
import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, collection, getDocs, query, where, addDoc,
  serverTimestamp, increment, arrayUnion, Bytes,
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
  await assertSucceeds(getDocs(query(collection(db('s1'), 'presence'), where('available', '==', true))));
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
  const r = { reporterId: 's1', reporterName: 'F', reportedId: 't1', reportedName: 'A', conversationId: 's1_t1', reason: 'words', details: '', status: 'open', createdAt: serverTimestamp() };
  await assertSucceeds(addDoc(collection(db('s1'), 'reports'), r));
  await assertFails(addDoc(collection(db('s1'), 'reports'), { ...r, reporterId: 's2' }));
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
