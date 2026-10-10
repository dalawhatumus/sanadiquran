import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/backend/user_stream.dart';

/// The per-user server streams keep going after a failure and switch users
/// straight away, so an approval or a call always arrives without a restart.
void main() {
  test('restarts after an error, and switches on sign-in and sign-out', () {
    fakeAsync((async) {
      final auth = StreamController<String?>();
      String? current;
      final servers = <String, List<StreamController<String>>>{};
      final seen = <String>[];
      final sub = followUser<String>(auth.stream, () => current, (uid) {
        final c = StreamController<String>();
        servers.putIfAbsent(uid, () => []).add(c);
        return c.stream;
      }, 'none').listen(seen.add);

      auth.add(null);
      async.flushMicrotasks();
      expect(seen, ['none']);

      current = 'a';
      auth.add('a');
      async.flushMicrotasks();
      servers['a']!.last.add('pending');
      async.flushMicrotasks();
      expect(seen.last, 'pending');

      // Permission denied right after signing in: tried again shortly.
      servers['a']!.last.addError(Exception('permission-denied'));
      async.flushMicrotasks();
      expect(servers['a']!.length, 1);
      async.elapse(const Duration(seconds: 3));
      expect(servers['a']!.length, 2);
      servers['a']!.last.add('approved');
      async.flushMicrotasks();
      expect(seen.last, 'approved');

      // A stream that just stops is started again too.
      servers['a']!.last.close();
      async.elapse(const Duration(seconds: 3));
      expect(servers['a']!.length, 3);

      // Another user: the old stream is dropped at once.
      current = 'b';
      auth.add('b');
      async.flushMicrotasks();
      expect(servers['b']!.length, 1);
      expect(servers['a']!.last.hasListener, isFalse);
      servers['b']!.last.add('b-data');
      async.flushMicrotasks();
      expect(seen.last, 'b-data');

      current = null;
      auth.add(null);
      async.flushMicrotasks();
      expect(seen.last, 'none');
      expect(servers['b']!.last.hasListener, isFalse);
      async.elapse(const Duration(minutes: 2));
      expect(servers['b']!.length, 1, reason: 'no retries once signed out');
      sub.cancel();
    });
  });
}
