import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thai_safe/features/authetication/data/user_model.dart';

class AuthService {
  final CollectionReference<Map<String, dynamic>> usersCollection =
      FirebaseFirestore.instance.collection('users');

  // READ: stream user by uid
  Stream<UserModel> getUser(String uid) {
    return usersCollection.doc(uid).snapshots().map(
      (doc) => UserModel.fromMap(doc.data()!),
    );
  }

  // CREATE: create user (use uid!)
  Future<void> createUser(UserModel user) {
    return usersCollection.doc(user.id).set(user.toMap());
  }

  // UPDATE: update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return usersCollection.doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) {
    return usersCollection.doc(uid).delete();
  }
}
