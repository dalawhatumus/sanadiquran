import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'log.dart';
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
  static const _teacherFreeId = 3;

  /// The only places a notification may open. Its payload is checked
  /// against these before the app navigates anywhere.
  static const routes = {'/athkar/morning', '/athkar/evening', homeRoute, teacherHomeRoute};
  static final _chatRoute = RegExp(r'^/chat/[A-Za-z0-9_-]{1,128}$');
  static final _notesRoute = RegExp(r'^/notes\?id=[A-Za-z0-9_-]{1,128}$');
  static final _incomingRoute = RegExp(r'^/call/incoming\?id=[A-Za-z0-9_-]{1,128}$');

  /// "A teacher is free": opens the student's home.
  static const homeRoute = '/s/home';

  /// A decision on a teacher's application: opens the teacher's home.
  static const teacherHomeRoute = '/t/home';

  static const _incomingId = 4;
  static const _missedId = 5;
  static const _decisionId = 6;
  static String? safeRoute(String? route) =>
      route != null &&
          (routes.contains(route) ||
              _chatRoute.hasMatch(route) ||
              _notesRoute.hasMatch(route) ||
              _incomingRoute.hasMatch(route))
      ? route
      : null;

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
          final route = safeRoute(r.payload);
          if (route != null) onOpen?.call(route);
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final route = safeRoute(launch?.notificationResponse?.payload);
      if ((launch?.didNotificationLaunchApp ?? false) && route != null) _launchRoute = route;
    } catch (e) {
      logIssue('Reminders unavailable: $e');
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
      logIssue('Reminders not scheduled: $e');
    }
  }

  /// Shows one notification now. Never throws: notifications are a help,
  /// and the app works without them.
  Future<void> _show({
    required int id,
    required String channel,
    required String channelName,
    required String channelDesc,
    required String title,
    required String body,
    required String payload,
    Importance importance = Importance.high,
    bool fullScreen = false,
    bool ongoing = false,
    int? timeoutMs,
  }) async {
    await _init();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channelName,
            channelDescription: channelDesc,
            importance: importance,
            priority: importance == Importance.high || importance == Importance.max
                ? Priority.high
                : Priority.defaultPriority,
            fullScreenIntent: fullScreen,
            category: fullScreen ? AndroidNotificationCategory.call : null,
            ongoing: ongoing,
            autoCancel: !ongoing,
            timeoutAfter: timeoutMs,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      logIssue('Notification $id not shown: $e');
    }
  }

  Future<void> _cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  /// Tells a student that a teacher is free now (they asked to be alerted).
  Future<void> teacherFree(S s) => _show(
    id: _teacherFreeId,
    channel: 'teacher_alerts',
    channelName: s.teacherAlertsChannel,
    channelDesc: s.teacherAlertsChannelDesc,
    title: s.teacherFreeTitle,
    body: s.teacherFreeBody,
    payload: homeRoute,
  );

  /// A new message in a chat the user isn't looking at. One notification
  /// per conversation (a newer message replaces it); tapping opens the chat.
  Future<void> newMessage({required S s, required String conversationId, required String from, required String text}) =>
      _show(
        // 1000+ keeps clear of the other ids.
        id: 1000 + (conversationId.hashCode & 0x3fffffff) % 1000000,
        channel: 'messages',
        channelName: s.messagesChannel,
        channelDesc: s.messagesChannelDesc,
        title: from,
        body: text,
        payload: '/chat/$conversationId',
      );

  /// A student is calling: full screen over the lock screen (where Android
  /// allows it; otherwise a high-priority alert). Cleared when answered,
  /// declined or missed, and by itself after the ringing time.
  Future<void> incomingCall({required S s, required String callId, required String studentName}) => _show(
    id: _incomingId,
    channel: 'calls',
    channelName: s.callsChannel,
    channelDesc: s.callsChannelDesc,
    title: s.incoming,
    body: studentName,
    payload: '/call/incoming?id=$callId',
    importance: Importance.max,
    fullScreen: true,
    ongoing: true,
    timeoutMs: 35000,
  );

  Future<void> cancelIncomingCall() => _cancel(_incomingId);

  /// A teacher missed a call.
  Future<void> missedCall({required S s, required String studentName}) => _show(
    id: _missedId,
    channel: 'missed_calls',
    channelName: s.missedChannel,
    channelDesc: s.missedChannelDesc,
    title: s.missedTitle,
    body: s.missedBodyName(studentName),
    payload: teacherHomeRoute,
    importance: Importance.defaultImportance,
  );

  /// A student's teacher added notes to a lesson.
  Future<void> lessonNotes({required S s, required String lessonId, required String teacherName}) => _show(
    id: 2000 + (lessonId.hashCode & 0x3fffffff) % 1000000,
    channel: 'lesson_notes',
    channelName: s.notesChannel,
    channelDesc: s.notesChannelDesc,
    title: s.notesFromName(teacherName),
    body: s.notesTapToRead,
    payload: '/notes?id=$lessonId',
    importance: Importance.defaultImportance,
  );

  /// An admin approved (or turned down) a teacher's application.
  Future<void> applicationDecided({required S s, required bool approved}) => _show(
    id: _decisionId,
    channel: 'account',
    channelName: s.accountChannel,
    channelDesc: s.accountChannelDesc,
    title: approved ? s.approvedTitle : s.notApprovedTitle,
    body: approved ? s.approvedBody : s.notApprovedBody,
    payload: teacherHomeRoute,
    importance: Importance.defaultImportance,
  );

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
