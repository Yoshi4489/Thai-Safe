import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';

class UserSafetyRepository {
  UserSafetyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SafetyFunctionsRepository? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _functions = functions ?? SafetyFunctionsRepository();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SafetyFunctionsRepository _functions;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in is required.');
    return uid;
  }

  Future<Map<String, dynamic>> load() async {
    final snapshot = await _firestore.collection('users').doc(_uid).get();
    return snapshot.data() ?? {};
  }

  Future<void> saveNotificationPreferences({
    required bool enabled,
    required double radiusKm,
    required String quietStart,
    required String quietEnd,
    required List<String> categories,
  }) {
    return _firestore.collection('users').doc(_uid).update({
      'notification_preferences': {
        'enabled': enabled,
        'radius_km': radiusKm,
        'quiet_start': quietStart,
        'quiet_end': quietEnd,
        'categories': categories,
      },
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveTrustedContacts(List<Map<String, String>> contacts) {
    return _firestore.collection('users').doc(_uid).update({
      'trusted_contacts': contacts.take(5).toList(growable: false),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> exportMyData() => _functions.exportMyData();
  Future<void> deleteMyAccount() => _functions.deleteMyAccount();
}
