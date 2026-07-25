import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? storage, FirebaseAuth? auth})
    : _storage = storage ?? FirebaseStorage.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in is required to upload files.');
    return uid;
  }

  Future<String> uploadIncidentImage({
    required String incidentId,
    required File file,
  }) async {
    final uid = _uid;
    final path = 'incident_media/$incidentId/$uid/${const Uuid().v4()}.jpg';
    await _storage
        .ref(path)
        .putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return path;
  }

  Future<String> uploadResponderEvidence(File file) async {
    final uid = _uid;
    final path = 'responder_evidence/$uid/${const Uuid().v4()}.jpg';
    await _storage
        .ref(path)
        .putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return path;
  }

  Future<String> uploadProfileImage(File file) async {
    final uid = _uid;
    final path = 'profile_images/$uid/${const Uuid().v4()}.jpg';
    final snapshot = await _storage
        .ref(path)
        .putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return snapshot.ref.getDownloadURL();
  }
}
