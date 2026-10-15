import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'photos.dart';

/// Profile photos on Firestore (the free plan has no file storage, so the
/// small JPEG is kept in a document).
///
/// - photos/{uid}: data (bytes, at most [maxPhotoBytes]), updatedAt. Readable
///   by the owner, admins and signed-in people of the same gender.
mixin FirestorePhotos implements PhotoApi {
  FirebaseFirestore get db;
  FirebaseAuth get auth;

  DocumentReference<Map<String, dynamic>> _photo(String uid) => db.collection('photos').doc(uid);

  @override
  Future<String> savePhoto(Uint8List jpeg) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    if (jpeg.length > maxPhotoBytes) throw ArgumentError('Photo too large');
    await _photo(uid).set({'data': Blob(jpeg), 'updatedAt': FieldValue.serverTimestamp()});
    return photoAvatar(uid);
  }

  @override
  Future<Uint8List?> photo(String uid) async {
    final b = (await _photo(uid).get()).data()?['data'];
    return b is Blob ? b.bytes : null;
  }

  @override
  Future<void> deleteOwnPhoto() async {
    final uid = auth.currentUser?.uid;
    if (uid != null) await _photo(uid).delete();
  }

  @override
  Future<void> removePhoto(String uid) => _photo(uid).delete();
}
