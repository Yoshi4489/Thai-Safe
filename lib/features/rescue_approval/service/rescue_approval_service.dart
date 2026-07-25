import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:thai_safe/core/services/firebase_storage_service.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';
import 'package:thai_safe/features/rescue_approval/data/resque_request_model.dart';

class RescueApprovalService {
  RescueApprovalService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    SafetyFunctionsRepository? functions,
    FirebaseStorageService? uploadService,
  }) : _applications = (firestore ?? FirebaseFirestore.instance).collection(
         'responder_applications',
       ),
       _storage = storage ?? FirebaseStorage.instance,
       _functions = functions ?? SafetyFunctionsRepository(),
       _uploadService = uploadService ?? FirebaseStorageService();

  final CollectionReference<Map<String, dynamic>> _applications;
  final FirebaseStorage _storage;
  final SafetyFunctionsRepository _functions;
  final FirebaseStorageService _uploadService;

  Future<void> createResponderApplication({
    required String organization,
    required String identityNumberLast4,
    required List<File> evidence,
  }) async {
    final paths = <String>[];
    for (final file in evidence) {
      paths.add(await _uploadService.uploadResponderEvidence(file));
    }
    await _functions.applyAsResponder(
      organization: organization,
      identityNumberLast4: identityNumberLast4,
      evidencePaths: paths,
    );
  }

  Stream<List<RescueRequestModel>> getRescueRequests() {
    return _applications
        .where('status', isEqualTo: 'pending')
        .orderBy('submitted_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RescueRequestModel.fromMap(doc.data(), doc.id))
              .toList(growable: false),
        );
  }

  Future<void> approveRescueRequest(
    String requestId,
    String reviewerId,
    String userId,
  ) => _functions.reviewResponder(uid: userId, action: 'approve');

  Future<void> rejectRescueRequest(
    String requestId,
    String reviewerId, {
    String reason = 'Application evidence could not be verified.',
  }) => _functions.reviewResponder(
    uid: requestId,
    action: 'reject',
    reason: reason,
  );

  Future<List<String>> evidenceUrls(RescueRequestModel request) {
    return Future.wait(
      request.evidencePaths.map((path) => _storage.ref(path).getDownloadURL()),
    );
  }
}
