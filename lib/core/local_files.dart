import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Audio the app keeps on the phone, all in its private storage: voice
/// notes played in chats (cached), and recordings being made (temporary).
/// Everything here is removed when the user signs out or deletes their
/// account, so the next person on a shared phone finds nothing.
abstract final class LocalFiles {
  /// Ids come from the server; anything but letters, digits, `_` and `-` is
  /// replaced, so a name can never point outside the app's folders.
  static String _safe(String id) => id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  static Future<Directory> _voiceDir() async => Directory('${(await getApplicationCacheDirectory()).path}/voice');

  /// Where a received voice note is cached once downloaded.
  static Future<File> voiceNote(String conversationId, String messageId) async =>
      File('${(await _voiceDir()).path}/${_safe(conversationId)}_${_safe(messageId)}.m4a');

  /// A fresh path for a new recording ([kind]: `voice` or `sample`).
  static Future<String> newRecording(String kind) async =>
      '${(await getTemporaryDirectory()).path}/${kind}_${DateTime.now().millisecondsSinceEpoch}.m4a';

  /// Where an applicant's recitation sample is saved for an admin to hear.
  static Future<File> applicationSample(String uid) async =>
      File('${(await getTemporaryDirectory()).path}/sample_${_safe(uid)}.m4a');

  /// Deletes every cached voice note and recording.
  static Future<void> clearAll() async {
    try {
      final voice = await _voiceDir();
      if (await voice.exists()) await voice.delete(recursive: true);
      final temp = await getTemporaryDirectory();
      await for (final f in temp.list()) {
        final name = f.uri.pathSegments.last;
        if (f is File && (name.startsWith('voice_') || name.startsWith('sample_'))) await f.delete();
      }
    } catch (_) {
      // Nothing to clear, or the folders aren't available (e.g. in tests).
    }
  }
}
