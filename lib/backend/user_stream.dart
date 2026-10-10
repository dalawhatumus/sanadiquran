import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';

/// A live stream for whoever is signed in: [build] for their uid, or
/// [signedOut] while no one is.
///
/// It switches straight to the new user on every sign-in or sign-out, and if
/// the server stream fails or stops (for example "permission denied" in the
/// moment after signing in, before Firestore has the new login, or a dropped
/// connection), it starts it again after a short wait, so changes made on
/// another phone (an approval, a call, a message) always arrive without
/// restarting the app.
Stream<T> perUser<T>(FirebaseAuth auth, Stream<T> Function(String uid) build, T signedOut) =>
    followUser(auth.authStateChanges().map((u) => u?.uid), () => auth.currentUser?.uid, build, signedOut);

/// [perUser] without Firebase: [uids] says who signs in and out, and
/// [currentUid] who is signed in now.
Stream<T> followUser<T>(
  Stream<String?> uids,
  String? Function() currentUid,
  Stream<T> Function(String uid) build,
  T signedOut,
) {
  late final StreamController<T> out;
  StreamSubscription<String?>? authSub;
  StreamSubscription<T>? inner;
  Timer? retry;
  var wait = 2;

  void stopInner() {
    retry?.cancel();
    retry = null;
    // Not awaited: cancelling must never hold up switching users.
    inner?.cancel();
    inner = null;
  }

  void watch(String uid) {
    stopInner();
    void again() {
      inner = null;
      retry?.cancel();
      retry = Timer(Duration(seconds: wait), () {
        if (!out.isClosed && currentUid() == uid) watch(uid);
      });
      wait = min(wait * 2, 60);
    }

    inner = build(uid).listen(
      (v) {
        wait = 2;
        out.add(v);
      },
      onError: (Object e, StackTrace st) {
        inner?.cancel();
        again();
      },
      onDone: again,
      cancelOnError: true,
    );
  }

  out = StreamController<T>(
    onListen: () {
      authSub = uids.listen((uid) {
        wait = 2;
        if (uid == null) {
          stopInner();
          out.add(signedOut);
        } else {
          watch(uid);
        }
      });
    },
    onCancel: () {
      stopInner();
      authSub?.cancel();
    },
  );
  return out.stream;
}
