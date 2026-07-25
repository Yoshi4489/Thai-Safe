import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thai_safe/core/config/firebase.dart';
import 'package:thai_safe/features/authentication/data/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> usersCollection = firestore
      .collection('users');

  Stream<UserModel?> authStateChanges() async* {
    await for (final firebaseUser in _auth.idTokenChanges()) {
      if (firebaseUser == null) {
        yield null;
        continue;
      }
      final token = await firebaseUser.getIdTokenResult();
      final role = _normalizeRole(token.claims?['role']);
      await for (final profile in getUserByUID(firebaseUser.uid)) {
        yield profile.copyWith(role: role);
      }
    }
  }

  String _normalizeRole(Object? value) {
    final role = value?.toString().toLowerCase();
    if (role == 'admin') return 'admin';
    if (role == 'responder' ||
        role == 'rescue' ||
        role == 'rescuer' ||
        role == 'officer') {
      return 'responder';
    }
    return 'user';
  }

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (error) {
        onError(error.message ?? 'OTP verification failed');
      },
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserModel> verifyOtpAndLogin({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await firebaseAuth.signInWithCredential(credential);
    final firebaseUser = result.user;
    if (firebaseUser == null) throw StateError('Authentication failed');

    final docRef = usersCollection.doc(firebaseUser.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      final user = UserModel(
        id: firebaseUser.uid,
        firstName: '',
        lastName: '',
        gender: '',
        profile_url: '',
        birthdate: DateTime.now(),
        tel: firebaseUser.phoneNumber ?? '',
        role: 'user',
        firstLogin: true,
        createdAt: DateTime.now(),
      );
      await docRef.set(user.toMap());
      return user;
    }
    final token = await firebaseUser.getIdTokenResult();
    return UserModel.fromMap(
      doc.data()!,
    ).copyWith(role: _normalizeRole(token.claims?['role']));
  }

  Stream<UserModel> getUserByUID(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) throw StateError('User profile not found');
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    const allowed = {
      'first_name',
      'last_name',
      'birthdate',
      'gender',
      'profile_url',
      'firstLogin',
      'notification_preferences',
      'trusted_contacts',
      'updated_at',
    };
    final safeData = Map<String, dynamic>.fromEntries(
      data.entries.where((entry) => allowed.contains(entry.key)),
    );
    return usersCollection.doc(uid).update(safeData);
  }

  Future<void> refreshRoleClaims() async {
    await _auth.currentUser?.getIdToken(true);
  }

  Future<void> logout() => firebaseAuth.signOut();
}
