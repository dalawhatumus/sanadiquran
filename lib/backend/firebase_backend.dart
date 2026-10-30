import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/log.dart';
import '../core/settings.dart';
import 'backend.dart';
import 'config.dart';
import 'firestore_admin.dart';
import 'firestore_calls.dart';
import 'firestore_chat.dart';
import 'firestore_lessons.dart';
import 'firestore_photos.dart';
import 'firestore_teachers.dart';
import 'teachers.dart';
import 'user_stream.dart';

/// The real server: Google sign-in through Firebase Auth, data in Firestore.
///
/// Collections (rules in firestore.rules):
/// - users/{uid}: name, role, gender, avatar, locale, age group,
///   nationality, phone and WhatsApp choice. Only the user and admins.
/// - teacherApplications/{uid}: answers and status. The user and admins;
///   only admins can approve.
/// - presence/{uid}: an approved teacher's "available" switch and gender.
///   Any signed-in user can read it (to count available teachers).
/// - photos/{uid}: the user's own profile photo (see firestore_photos.dart).
/// - admins/{uid}: who can review applications. Added by hand in the console.
class FirebaseBackend
    with FirestoreChat, FirestoreCalls, FirestoreLessons, FirestoreAdmin, FirestoreTeachers, FirestorePhotos
    implements Backend {
  FirebaseBackend();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  FirebaseAuth get auth => _auth;

  @override
  FirebaseFirestore get db => _db;
  bool _googleReady = false;

  @override
  bool get live => true;

  @override
  String? get accountEmail => _auth.currentUser?.email;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _doc(String collection, String uid) => _db.collection(collection).doc(uid);

  /// Runs [build] for the signed-in user, and again whenever that changes.
  Stream<T> _forUser<T>(Stream<T> Function(String uid) build, {required T signedOut}) =>
      perUser(_auth, build, signedOut);

  /// Asks Google for the user's account and returns it with a Firebase
  /// credential for it. Throws [SignInCancelled] if the user closes it.
  Future<(GoogleSignInAccount, AuthCredential)> _google() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(serverClientId: FirebaseConfig.webClientId);
      _googleReady = true;
    }
    // First the quiet way: an account this phone already used for Sanadi
    // signs in with no picker at all. Otherwise the account picker (one tap
    // when there's a single Google account on the phone).
    GoogleSignInAccount? quick;
    try {
      quick = await google.attemptLightweightAuthentication();
    } catch (e) {
      logIssue('Quiet Google sign-in: $e');
    }
    final GoogleSignInAccount account;
    try {
      account = quick ?? await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw const SignInCancelled();
      rethrow;
    }
    return (account, GoogleAuthProvider.credential(idToken: account.authentication.idToken));
  }

  @override
  Future<SignedInUser> signIn() async {
    final (account, credential) = await _google();
    final result = await _auth.signInWithCredential(credential);
    final user = result.user!;

    final saved = await _doc('users', user.uid).get();
    SavedProfile? profile;
    final data = saved.data();
    if (data != null) {
      final app = await _doc('teacherApplications', user.uid).get();
      profile = SavedProfile(
        name: (data['name'] as String?) ?? '',
        role: UserRole.values.where((r) => r.name == data['role']).firstOrNull,
        gender: Gender.values.where((g) => g.name == data['gender']).firstOrNull,
        avatar: data['avatar'] as String?,
        teacherStatus: _status(app.data()),
        ageGroup: data['ageGroup'] as String?,
        nationality: data['nationality'] as String?,
        phone: data['phone'] as String?,
        whatsapp: data['whatsapp'] == true,
      );
    }
    return SignedInUser(uid: user.uid, googleName: user.displayName ?? account.displayName, profile: profile);
  }

  /// At most [max] characters (the server refuses longer text).
  static String _clip(String s, int max) => s.length <= max ? s : s.substring(0, max);

  static TeacherStatus _status(Map<String, dynamic>? app) =>
      TeacherStatus.values.where((s) => s.name == app?['status']).firstOrNull ?? TeacherStatus.none;

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleReady) await GoogleSignIn.instance.signOut();
  }

  @override
  Future<void> saveProfile(AppSettings s) async {
    final uid = _uid;
    if (uid == null) return;
    final name = _clip(s.name.trim(), 80);
    await _doc('users', uid).set({
      'name': name,
      'role': s.role?.name,
      'gender': s.gender?.name,
      'avatar': s.avatar,
      'locale': s.locale?.languageCode,
      'ageGroup': s.ageGroup,
      'nationality': s.nationality,
      'phone': s.phone,
      'whatsapp': s.whatsapp,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Keep the name and picture the other person sees in chats up to date.
    final convs = await _db.collection('conversations').where('members', arrayContains: uid).get();
    final batch = _db.batch();
    var changed = false;
    for (final c in convs.docs) {
      final names = (c.data()['names'] as Map?) ?? const {};
      final avatars = (c.data()['avatars'] as Map?) ?? const {};
      if (names[uid] != name || avatars[uid] != s.avatar) {
        batch.update(c.reference, {'names.$uid': name, 'avatars.$uid': s.avatar});
        changed = true;
      }
    }
    if (changed) await batch.commit();
  }

  @override
  Future<void> submitApplication({
    required String name,
    required Gender? gender,
    required Map<String, String> answers,
    Uint8List? sample,
    int sampleSec = 0,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    // The recording is kept apart, so the list of applications stays light.
    if (sample != null) {
      await _doc(
        'applicationSamples',
        uid,
      ).set({'data': Blob(sample), 'durationSec': sampleSec, 'createdAt': FieldValue.serverTimestamp()});
    }
    await _doc('teacherApplications', uid).set({
      'name': _clip(name.trim(), 80),
      'gender': gender?.name,
      'answers': answers,
      'order': answers.keys.toList(),
      'sampleSec': sample == null ? 0 : sampleSec,
      'status': TeacherStatus.pending.name,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<TeacherStatus> teacherStatus() => _forUser(
    (uid) => _doc('teacherApplications', uid).snapshots().map((d) => _status(d.data())),
    signedOut: TeacherStatus.none,
  );

  @override
  Stream<String> applicationReason() => _forUser(
    (uid) => _doc('teacherApplications', uid).snapshots().map((d) => (d.data()?['reason'] as String?) ?? ''),
    signedOut: '',
  ).handleError((_) {});

  @override
  Future<Uint8List?> applicationSample(String uid) async {
    final d = await _doc('applicationSamples', uid).get();
    final b = d.data()?['data'];
    return b is Blob ? b.bytes : null;
  }

  @override
  Future<void> resolveReport(String id) =>
      _db.collection('reports').doc(id).update({'status': 'resolved', 'resolvedBy': _uid});

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    // Deleting an account needs a recent sign-in. Confirm it first, before
    // anything is deleted, so a cancelled confirmation leaves everything as
    // it was. Re-authenticating (not signing in afresh) means Firebase
    // refuses a different Google account ("user-mismatch"): only the
    // signed-in account can ever be deleted.
    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null || DateTime.now().difference(lastSignIn) > const Duration(minutes: 4)) {
      await user.reauthenticateWithCredential((await _google()).$2);
    }
    // Personal data next (the rules allow it only while signed in).
    for (final c in ['presence', 'waiting', 'photos', 'applicationSamples', 'teacherApplications', 'users']) {
      await _doc(c, uid).delete().catchError((Object e) => logIssue('Delete $c: $e'));
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      await user.reauthenticateWithCredential((await _google()).$2);
      await user.delete();
    }
    await signOut();
  }

  @override
  Future<void> setAvailable({required bool on, required Gender? gender, String name = '', String? avatar}) async {
    final uid = _uid;
    if (uid == null) return;
    await _doc('presence', uid).set({
      'available': on,
      'gender': gender?.name,
      // Shown to students of the same gender in the teacher list.
      'name': _clip(name.trim(), 80),
      'avatar': avatar,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<int> availableTeachers(Gender? gender) => gender == null
      ? Stream.value(0)
      : teachers(gender).map((list) => list.where((t) => t.state == TeacherState.available).length);

  @override
  Stream<bool> isAdmin() =>
      _forUser((uid) => _doc('admins', uid).snapshots().map((d) => d.exists).handleError((_) {}), signedOut: false);

  @override
  Stream<List<TeacherApplication>> pendingApplications() => _forUser(
    (uid) => _db
        .collection('teacherApplications')
        .where('status', isEqualTo: TeacherStatus.pending.name)
        .snapshots()
        .map((s) {
          final list = [
            for (final d in s.docs)
              TeacherApplication(
                uid: d.id,
                name: (d['name'] as String?) ?? '',
                gender: Gender.values.where((g) => g.name == d.data()['gender']).firstOrNull,
                answers: _ordered(d.data()),
                submitted: (d.data()['submittedAt'] as Timestamp?)?.toDate(),
                sampleSec: (d.data()['sampleSec'] as num?)?.toInt() ?? 0,
              ),
          ];
          list.sort((a, b) => (a.submitted ?? DateTime(2100)).compareTo(b.submitted ?? DateTime(2100)));
          return list;
        }),
    signedOut: const [],
  );

  static Map<String, String> _ordered(Map<String, dynamic> d) {
    final answers = ((d['answers'] as Map?) ?? const {}).cast<String, Object?>();
    final order = ((d['order'] as List?) ?? answers.keys.toList()).cast<String>();
    return {
      for (final k in order)
        if (answers[k] != null) k: '${answers[k]}',
    };
  }

  @override
  Future<void> decide(String uid, {required bool approve, String reason = ''}) =>
      _doc('teacherApplications', uid).update({
        'status': (approve ? TeacherStatus.approved : TeacherStatus.rejected).name,
        'reason': reason.trim(),
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': _uid,
      });
}
