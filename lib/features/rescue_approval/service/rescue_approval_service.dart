import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thai_safe/features/rescue_approval/data/resque_request_model.dart';

class RescueApprovalService {
  final CollectionReference<Map<String, dynamic>> _requestRef =
      FirebaseFirestore.instance.collection('rescue_requests');

  Stream<List<RescueRequestModel>> getRescueRequests() {
    return _requestRef
    .where("status", isEqualTo: "pending")
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RescueRequestModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> approveRescueRequest(String requestId, String reviewerId) async {
    await _requestRef.doc(requestId).update({
      'status': "approved",
      "reviewedBy": reviewerId,
      "reviewedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRescueRequest(String requestId, String reviewerId) async {
    await _requestRef.doc(requestId).update({
      'status': "rejected",
      "reviewedBy": reviewerId,
      "reviewedAt": FieldValue.serverTimestamp(),
    });
  }
}
