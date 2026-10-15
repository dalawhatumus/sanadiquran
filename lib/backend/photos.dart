import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/local_files.dart';
import 'backend.dart';

/// The largest photo the server accepts (it is made about 256 pixels
/// square and compressed before sending, so it is usually far smaller).
const maxPhotoBytes = 150000;

/// A person's own photo, kept on the server as a small JPEG. Their
/// `avatar` is then `photo:{uid}:{version}`, so everywhere a picture is
/// shown (chats, calls, the teacher list) finds it, and a new version is
/// fetched only when the photo changes.
abstract interface class PhotoApi {
  /// Saves this user's photo; returns the avatar value that points to it.
  Future<String> savePhoto(Uint8List jpeg);

  /// Someone's photo, or null if they have none (or it was removed).
  Future<Uint8List?> photo(String uid);

  /// Deletes this user's own photo.
  Future<void> deleteOwnPhoto();

  /// Removes someone's photo (admins only).
  Future<void> removePhoto(String uid);
}

/// The person an avatar value's photo belongs to, or null if [avatar] is
/// one of the drawn pictures (or initials).
String? photoOwner(String? avatar) {
  final m = _photoValue.firstMatch(avatar ?? '');
  return m?.group(1);
}

final _photoValue = RegExp(r'^photo:([A-Za-z0-9]{1,128}):[a-z0-9]{1,12}$');

/// The avatar value for [uid]'s photo saved now.
String photoAvatar(String uid) => 'photo:$uid:${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

/// Photos already loaded, by avatar value (which changes with each new
/// photo, so an old one is never shown).
final _memory = <String, Uint8List?>{};

/// Keeps a photo just saved, so it shows at once (and offline).
void rememberPhoto(String avatar, Uint8List bytes) {
  _memory[avatar] = bytes;
  unawaited(_cache(avatar, bytes));
}

Future<void> _cache(String avatar, Uint8List bytes) async {
  try {
    final file = await LocalFiles.photo(avatar);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  } catch (_) {}
}

/// The photo for an avatar value: from memory, then this phone's cache,
/// then the server. Null while there is none.
final photoProvider = FutureProvider.family<Uint8List?, String>((ref, avatar) async {
  if (_memory.containsKey(avatar)) return _memory[avatar];
  final uid = photoOwner(avatar);
  if (uid == null) return null;
  File? file;
  try {
    file = await LocalFiles.photo(avatar);
    if (await file.exists()) return _memory[avatar] = await file.readAsBytes();
  } catch (_) {
    file = null;
  }
  final bytes = await ref.read(backendProvider).photo(uid);
  _memory[avatar] = bytes;
  if (bytes != null && file != null) unawaited(_cache(avatar, bytes));
  return bytes;
});

/// Demo mode: photos are kept in memory.
mixin DemoPhotos implements PhotoApi {
  final _photos = <String, Uint8List>{};

  String get _demoUid => 'demo';

  @override
  Future<String> savePhoto(Uint8List jpeg) async {
    if (jpeg.length > maxPhotoBytes) throw ArgumentError('Photo too large');
    _photos[_demoUid] = jpeg;
    return photoAvatar(_demoUid);
  }

  @override
  Future<Uint8List?> photo(String uid) async => _photos[uid];

  @override
  Future<void> deleteOwnPhoto() async => _photos.remove(_demoUid);

  @override
  Future<void> removePhoto(String uid) async => _photos.remove(uid);
}
