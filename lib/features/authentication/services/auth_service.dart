import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thai_safe/core/config/firebase.dart';
import 'package:thai_safe/features/authentication/data/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> usersCollection = firestore
      .collection('users');

  Stream<UserModel?> authStateChanges() {
    return _auth
        .authStateChanges()
        .map((user) {
          if (user == null) return null;
          return getUserByUID(user.uid);
        })
        .asyncExpand((stream) => stream);
  }

  /* =========================
   * SEND OTP
   * ========================= */
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto verify (Android only sometimes)
        await firebaseAuth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'OTP verification failed');
      },

      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /* =========================
   * VERIFY OTP + LOGIN
   * ========================= */
  Future<UserModel> verifyOtpAndLogin({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await firebaseAuth.signInWithCredential(credential);

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Authentication failed');
    }

    final uid = user.uid;
    final docRef = usersCollection.doc(uid);
    final doc = await docRef.get();

    // 🔥 FIRST TIME LOGIN → CREATE USER
    if (!doc.exists) {
      final newUser = UserModel(
        id: uid,
        firstName: '',
        lastName: '',
        gender: '',
        profile_url: "",
        age: 0,
        tel: user.phoneNumber!,
        role: 'USER',
        firstLogin: true,
        createdAt: DateTime.now().toIso8601String(),
      );

      await docRef.set(newUser.toMap());
      return newUser;
    }

    return UserModel.fromMap(doc.data()!);
  }

  /* =========================
   * READ USER BY UID
   * ========================= */
  Stream<UserModel> getUserByUID(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('User not found');
      }
      return UserModel.fromMap(doc.data()!);
    });
  }

  /* =========================
   * UPDATE USER
   * ========================= */
  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return usersCollection.doc(uid).update(data);
  }

  /* =========================
   * LOGOUT
   * ========================= */
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
}
