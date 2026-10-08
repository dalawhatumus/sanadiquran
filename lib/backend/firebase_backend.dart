import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/settings.dart';
import 'backend.dart';
import 'config.dart';

/// The real server: Google sign-in through Firebase Auth, data in Firestore.
///
/// Collections (rules in firestore.rules):
/// - users/{uid}: name, role, gender, avatar, locale. Only the user.
/// - teacherApplications/{uid}: answers and status. The user and admins;
///   only admins can approve.
/// - presence/{uid}: an approved teacher's "available" switch and gender.
///   Any signed-in user can read it (to count available teachers).
/// - admins/{uid}: who can review applications. Added by hand in the console.
class FirebaseBackend implements Backend {
  FirebaseBackend();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  bool _googleReady = false;

  @override
  bool get live => true;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _doc(String collection, String uid) => _db.collection(collection).doc(uid);

  /// Runs [build] for the signed-in user, and again whenever that changes.
  Stream<T> _forUser<T>(Stream<T> Function(String uid) build, {required T signedOut}) =>
      _auth.authStateChanges().asyncExpand((u) => u == null ? Stream.value(signedOut) : build(u.uid));

  @override
  Future<SignedInUser> signIn() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(serverClientId: FirebaseConfig.webClientId);
      _googleReady = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw const SignInCancelled();
      rethrow;
    }
    final idToken = account.authentication.idToken;
    final result = await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
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
      );
    }
    return SignedInUser(uid: user.uid, googleName: user.displayName ?? account.displayName, profile: profile);
  }

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
    await _doc('users', uid).set({
      'name': s.name.trim(),
      'role': s.role?.name,
      'gender': s.gender?.name,
      'avatar': s.avatar,
      'locale': s.locale?.languageCode,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> submitApplication({
    required String name,
    required Gender? gender,
    required Map<String, String> answers,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _doc('teacherApplications', uid).set({
      'name': name.trim(),
      'gender': gender?.name,
      'answers': answers,
      'order': answers.keys.toList(),
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
  Future<void> setAvailable({required bool on, required Gender? gender}) async {
    final uid = _uid;
    if (uid == null) return;
    await _doc(
      'presence',
      uid,
    ).set({'available': on, 'gender': gender?.name, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Stream<int> availableTeachers(Gender? gender) => _forUser((uid) {
    Query<Map<String, dynamic>> q = _db.collection('presence').where('available', isEqualTo: true);
    if (gender != null) q = q.where('gender', isEqualTo: gender.name);
    return q.snapshots().map((s) => s.docs.where((d) => d.id != uid).length);
  }, signedOut: 0);

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
