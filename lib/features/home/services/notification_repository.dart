import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.data,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> data;
}

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in is required.');
    return _firestore.collection('users').doc(uid).collection('notifications');
  }

  Stream<List<UserNotification>> watch() {
    return _collection
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final value = doc.data();
                return UserNotification(
                  id: doc.id,
                  title: value['title']?.toString() ?? 'Thai Safe',
                  body: value['body']?.toString() ?? '',
                  createdAt:
                      (value['created_at'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  isRead: value['read_at'] != null,
                  data: Map<String, dynamic>.from(value['data'] as Map? ?? {}),
                );
              })
              .toList(growable: false),
        );
  }

  Future<void> markRead(String id) {
    return _collection.doc(id).update({
      'read_at': FieldValue.serverTimestamp(),
    });
  }
}
