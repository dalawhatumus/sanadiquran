import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'settings.dart';
import 'strings.dart';

/// Times of the morning and evening athkar reminders, in minutes after
/// midnight.
class ReminderTimes {
  const ReminderTimes(this.morning, this.evening);

  final int morning;
  final int evening;

  TimeOfDay get morningTime => TimeOfDay(hour: morning ~/ 60, minute: morning % 60);
  TimeOfDay get eveningTime => TimeOfDay(hour: evening ~/ 60, minute: evening % 60);
}

class ReminderTimesNotifier extends Notifier<ReminderTimes> {
  static const _kMorning = 'reminder.morning';
  static const _kEvening = 'reminder.evening';

  @override
  ReminderTimes build() {
    final p = ref.read(sharedPreferencesProvider);
    // After Fajr, and after Asr, for most of the year.
    return ReminderTimes(p.getInt(_kMorning) ?? 7 * 60, p.getInt(_kEvening) ?? 16 * 60 + 30);
  }

  void setMorning(TimeOfDay t) {
    final m = t.hour * 60 + t.minute;
    ref.read(sharedPreferencesProvider).setInt(_kMorning, m);
    state = ReminderTimes(m, state.evening);
  }

  void setEvening(TimeOfDay t) {
    final m = t.hour * 60 + t.minute;
    ref.read(sharedPreferencesProvider).setInt(_kEvening, m);
    state = ReminderTimes(state.morning, m);
  }
}

final reminderTimesProvider = NotifierProvider<ReminderTimesNotifier, ReminderTimes>(ReminderTimesNotifier.new);

/// Daily athkar reminders, scheduled on the phone itself (no server, works
/// offline). Tapping one opens that set of athkar.
class Reminders {
  Reminders._();

  static final instance = Reminders._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Where a tapped reminder should take the user (while the app runs).
  void Function(String route)? onOpen;

  /// The athkar to open when the app was started by tapping a reminder;
  /// read (once) by the splash screen, which opens it over the home screen.
  String? takeLaunchRoute() {
    final r = _launchRoute;
    _launchRoute = null;
    return r;
  }

  String? _launchRoute;

  @visibleForTesting
  set launchRouteForTest(String? route) => _launchRoute = route;

  static const _morningId = 1;
  static const _eveningId = 2;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      tzdata.initializeTimeZones();
      try {
        final local = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(local.identifier));
      } catch (_) {
        // Keep UTC; times are then approximate, but reminders still come.
      }
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
        onDidReceiveNotificationResponse: (r) {
          final route = r.payload;
          if (route != null) onOpen?.call(route);
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final route = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) && route != null) _launchRoute = route;
    } catch (e) {
      debugPrint('Reminders unavailable: $e');
    }
  }

  /// Schedules (or cancels) the two daily reminders.
  Future<void> apply({required bool on, required ReminderTimes times, required S s}) async {
    await _init();
    try {
      await _plugin.cancel(id: _morningId);
      await _plugin.cancel(id: _eveningId);
      if (!on) return;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'athkar_reminders',
          s.remindersChannel,
          channelDescription: s.remindersChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );
      Future<void> daily(int id, int minutes, String title, String body, String route) => _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _next(minutes),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: route,
      );
      await daily(_morningId, times.morning, s.morningAthkar, s.morningReminderBody, '/athkar/morning');
      await daily(_eveningId, times.evening, s.eveningAthkar, s.eveningReminderBody, '/athkar/evening');
    } catch (e) {
      debugPrint('Reminders not scheduled: $e');
    }
  }

  static tz.TZDateTime _next(int minutes) {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    return at;
  }
}

/// Keeps the scheduled reminders in step with the settings (on/off, times,
/// language). Watched once, by the app.
final remindersSyncProvider = Provider<void>((ref) {
  final on = ref.watch(settingsProvider.select((s) => s.remindersOn && s.locale != null && s.signedIn));
  final ar = ref.watch(settingsProvider.select((s) => s.locale?.languageCode == 'ar'));
  final female = ref.watch(settingsProvider.select((s) => s.female));
  final times = ref.watch(reminderTimesProvider);
  Reminders.instance.apply(
    on: on,
    times: times,
    s: S(ar: ar, female: female),
  );
});

/// The next reminder from now: (is it the morning one, at what time).
(bool, TimeOfDay) nextReminder(ReminderTimes t) {
  final now = TimeOfDay.now();
  final m = now.hour * 60 + now.minute;
  if (m < t.morning) return (true, t.morningTime);
  if (m < t.evening) return (false, t.eveningTime);
  return (true, t.morningTime);
}
