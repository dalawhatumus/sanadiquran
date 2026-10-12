import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';

/// A teacher who misses [limit] calls in a row is set to away, so students
/// aren't sent to someone who isn't there. The state is whether to show the
/// "We set you to away" notice on the teacher's home.
class AutoAway extends Notifier<bool> {
  static const limit = 2;
  static const _key = 'autoAwayNotice';

  int _inARow = 0;

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? false;

  /// A call rang out (or the student moved on) without an answer.
  void missed() {
    if (++_inARow < limit) return;
    _inARow = 0;
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(available: false));
    state = true;
    ref.read(sharedPreferencesProvider).setBool(_key, true);
  }

  /// The teacher answered or declined: they are there.
  void responded() => _inARow = 0;

  /// The notice was read, or the teacher switched "available" back on.
  void dismiss() {
    _inARow = 0;
    if (!state) return;
    state = false;
    ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final autoAwayProvider = NotifierProvider<AutoAway, bool>(AutoAway.new);
