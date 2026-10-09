import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'backend.dart';

/// A 1:1 conversation between a student and a teacher, as seen by this user.
class Conversation {
  const Conversation({
    required this.id,
    required this.otherUid,
    required this.otherName,
    this.otherAvatar,
    this.otherRole,
    this.lastText = '',
    this.lastVoiceSec,
    this.lastAt,
    this.unread = 0,
    this.blockedByMe = false,
    this.blockedByOther = false,
  });

  final String id;
  final String otherUid;
  final String otherName;
  final String? otherAvatar;
  final UserRole? otherRole;

  /// Preview of the last message: its text, or empty with [lastVoiceSec] set
  /// for a voice note.
  final String lastText;
  final int? lastVoiceSec;
  final DateTime? lastAt;
  final int unread;
  final bool blockedByMe;
  final bool blockedByOther;

  bool get blocked => blockedByMe || blockedByOther;
}

enum MessageType { text, voice }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    this.text = '',
    this.durationSec = 0,
    this.sentAt,
    this.pending = false,
  });

  final String id;
  final String senderId;
  final MessageType type;
  final String text;
  final int durationSec;

  /// Null until the server has stamped it.
  final DateTime? sentAt;

  /// Saved on the phone but not yet on the server (e.g. offline).
  final bool pending;
}

/// Someone an admin can connect (a student or an approved teacher).
class PersonSummary {
  const PersonSummary({required this.uid, required this.name, this.gender, this.role});

  final String uid;
  final String name;
  final Gender? gender;
  final UserRole? role;
}

/// A report about a user, for admins.
class UserReport {
  const UserReport({
    required this.id,
    required this.reporterName,
    required this.reportedName,
    required this.reason,
    this.details = '',
    this.at,
  });

  final String id;
  final String reporterName;
  final String reportedName;
  final String reason;
  final String details;
  final DateTime? at;
}

/// Why someone is reported (stored in English for the admin).
enum ReportReason { words, respect, personal, other }

/// Longest voice note, in seconds (keeps each note small enough to store
/// with the messages, so no paid file storage is needed).
const maxVoiceSeconds = 180;

/// Chat between a student and their teacher: text and voice notes, unread
/// counts, delete, block and report. Conversations are opened by an admin
/// for now; from the calls update on, a first lesson opens them.
abstract interface class ChatApi {
  /// This user's id, or null when signed out.
  String? get myUid;

  /// This user's conversations, newest activity first.
  Stream<List<Conversation>> conversations();

  /// The messages of a conversation, oldest first.
  Stream<List<ChatMessage>> messages(String conversationId);

  Future<void> sendText(String conversationId, String text);

  /// [audio] is AAC (m4a), at most [maxVoiceSeconds] long.
  Future<void> sendVoice(String conversationId, Uint8List audio, int durationSec);

  /// The recording of a voice note.
  Future<Uint8List> voiceAudio(String conversationId, String messageId);

  /// Deletes one of this user's own messages, for both people.
  Future<void> deleteMessage(String conversationId, ChatMessage message);

  /// Marks the conversation as read by this user.
  Future<void> markRead(String conversationId);

  Future<void> setBlocked(String conversationId, {required bool blocked});

  Future<void> report({
    required String conversationId,
    required String reportedUid,
    required ReportReason reason,
    String details = '',
  });

  /// Whether a teacher has their "available" switch on.
  Stream<bool> teacherAvailable(String uid);

  // ---- Admins ----

  Future<List<PersonSummary>> students();

  Future<List<PersonSummary>> approvedTeachers();

  /// Opens a conversation between a student and a teacher of the same
  /// gender.
  Future<void> connect(PersonSummary student, PersonSummary teacher);

  Stream<List<UserReport>> reports();
}

final conversationsProvider = StreamProvider<List<Conversation>>((ref) => ref.watch(backendProvider).conversations());

final messagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, id) => ref.watch(backendProvider).messages(id),
);

/// Unread messages across all conversations (for the Messages tab badge).
final unreadTotalProvider = Provider<int>(
  (ref) => (ref.watch(conversationsProvider).value ?? const []).fold(0, (n, c) => n + c.unread),
);

final teacherAvailableProvider = StreamProvider.family<bool, String>(
  (ref, uid) => ref.watch(backendProvider).teacherAvailable(uid),
);

final reportsProvider = StreamProvider<List<UserReport>>((ref) => ref.watch(backendProvider).reports());

/// Demo mode: one sample conversation kept in memory, so the chat screens
/// can be tried (and tested) without a server.
mixin DemoChat implements ChatApi {
  static const _me = 'demo';
  static const _other = 'demo-teacher';
  static const _cid = 'demo-chat';

  final _msgs = <ChatMessage>[
    ChatMessage(
      id: 'm1',
      senderId: _other,
      type: MessageType.text,
      text: 'As-salamu alaykum. Well done today, your recitation of Al-Mulk is getting stronger.',
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    ChatMessage(
      id: 'm2',
      senderId: _other,
      type: MessageType.voice,
      durationSec: 42,
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    ChatMessage(
      id: 'm3',
      senderId: _me,
      type: MessageType.text,
      text: 'Wa alaykum as-salam. JazakAllahu khayran!',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];
  final _audio = <String, Uint8List>{};
  int _unread = 1;
  bool _blocked = false;
  final _changes = StreamController<void>.broadcast();

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  void _changed() => _changes.add(null);

  @override
  String? get myUid => _me;

  @override
  Stream<List<Conversation>> conversations() => _watch(() {
    final last = _msgs.isEmpty ? null : _msgs.last;
    return [
      Conversation(
        id: _cid,
        otherUid: _other,
        otherName: 'Aisha Rahman',
        otherAvatar: 'ft2',
        otherRole: UserRole.teacher,
        lastText: last?.type == MessageType.text ? last!.text : '',
        lastVoiceSec: last?.type == MessageType.voice ? last!.durationSec : null,
        lastAt: last?.sentAt,
        unread: _unread,
        blockedByMe: _blocked,
      ),
    ];
  });

  @override
  Stream<List<ChatMessage>> messages(String conversationId) => _watch(() => List.of(_msgs));

  @override
  Future<void> sendText(String conversationId, String text) async {
    _msgs.add(
      ChatMessage(
        id: 'm${_msgs.length + 1}',
        senderId: _me,
        type: MessageType.text,
        text: text,
        sentAt: DateTime.now(),
      ),
    );
    _changed();
  }

  @override
  Future<void> sendVoice(String conversationId, Uint8List audio, int durationSec) async {
    final id = 'm${_msgs.length + 1}';
    _audio[id] = audio;
    _msgs.add(
      ChatMessage(id: id, senderId: _me, type: MessageType.voice, durationSec: durationSec, sentAt: DateTime.now()),
    );
    _changed();
  }

  @override
  Future<Uint8List> voiceAudio(String conversationId, String messageId) async =>
      _audio[messageId] ?? (throw StateError('This sample voice note has no recording.'));

  @override
  Future<void> deleteMessage(String conversationId, ChatMessage message) async {
    _msgs.removeWhere((m) => m.id == message.id);
    _changed();
  }

  @override
  Future<void> markRead(String conversationId) async {
    if (_unread == 0) return;
    _unread = 0;
    _changed();
  }

  @override
  Future<void> setBlocked(String conversationId, {required bool blocked}) async {
    _blocked = blocked;
    _changed();
  }

  @override
  Future<void> report({
    required String conversationId,
    required String reportedUid,
    required ReportReason reason,
    String details = '',
  }) async {}

  @override
  Stream<bool> teacherAvailable(String uid) => Stream.value(true);

  @override
  Future<List<PersonSummary>> students() async => const [];

  @override
  Future<List<PersonSummary>> approvedTeachers() async => const [];

  @override
  Future<void> connect(PersonSummary student, PersonSummary teacher) async {}

  @override
  Stream<List<UserReport>> reports() => Stream.value(const []);
}
