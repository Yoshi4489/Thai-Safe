import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thai_safe/core/config/firebase.dart';
import 'package:thai_safe/features/profile/data/medical_profile_model.dart';

class MedicalProfileService {
  final _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> medicalCollection = firestore.collection("medical_profiles");

  Stream<MedicalProfileModel?> medicalStateChange() async* {
    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        yield null;
      } else {
        yield* getMedicalProfileByUID(user.uid);
      }
    }
  }


  /* ---------------------------
   *  CREATE MEDICAL PROFILE
   * --------------------------- */
  Future<void> createMedicalProfile(String userUID) async {
    final existing = await medicalCollection
        .where("user_id", isEqualTo: userUID)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("User medical profile already exists");
    }

    final docRef = medicalCollection.doc();
    final medicalId = docRef.id;

    final newMedicalProfile = MedicalProfileModel(
      id: medicalId,
      user_id: userUID,
      blood_type: "",
      chronic_diseases: "",
      regular_medications: "",
      allergies: "",
      contact_list: [],
      updated_at: DateTime.now(),
    );

    await docRef.set(newMedicalProfile.toMap());
  }

  /* ---------------------------
   *  GET MEDICAL PROFILE BY UID
   * --------------------------- */
   Stream<MedicalProfileModel> getMedicalProfileByUID(String uid) {
    return medicalCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception("Medical Profile Not Found");
      }
      return MedicalProfileModel.fromMap(doc.data()!);
    });
   }

  /* ------------------------------
   *  UPDATE MEDICAL PROFILE
   * ------------------------------ */
   Future<void> updateMedicalProfile(String uid, Map<String, dynamic> data) {
    return medicalCollection.doc(uid).update(data);
   }
}