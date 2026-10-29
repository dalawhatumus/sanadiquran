import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../backend/backend.dart';
import '../../backend/calls.dart';
import '../../backend/sessions.dart';
import '../../core/background.dart';
import '../../core/reminders.dart';
import '../../core/router.dart';
import '../../core/screen.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/avatars.dart';
import '../../widgets/ui.dart';
import '../lessons/lessons_ui.dart';
import '../quran/quran_data.dart';
import '../settings/more_screens.dart';
import 'call_controller.dart';
import 'missed_calls.dart';

part 'connecting_screen.dart';
part 'in_call_screen.dart';
part 'incoming_call_screen.dart';
part 'call_ended_screens.dart';

/// The call screens: finding or ringing, the call itself, an incoming call,
/// and the end screens, each in its own part file.

String _clock(S s, int secs) =>
    s.n('${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}');

/// The other person's name and picture during a call (sample ones in demo
/// mode, where the call has no real person).
(String, String, String?) _other(S s, CallState st) {
  final teacher = st.asTeacher;
  if (st.otherName.isEmpty) {
    return teacher
        ? (s.studentName, s.studentInitial, sampleStudentAvatar(s.female))
        : (s.teacherName, s.teacherInitials, sampleTeacherAvatar(s.female));
  }
  final n = st.otherName.trim();
  return (n, n.isEmpty ? '?' : n.characters.first.toUpperCase(), st.otherAvatar);
}
