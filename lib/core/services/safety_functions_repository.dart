import 'package:cloud_functions/cloud_functions.dart';

class QuickIncidentRequest {
  const QuickIncidentRequest({
    required this.clientRequestId,
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    this.lastKnownLatitude,
    this.lastKnownLongitude,
    this.medicalSummaryConsent = false,
  });

  final String clientRequestId;
  final double latitude;
  final double longitude;
  final double accuracyM;
  final double? lastKnownLatitude;
  final double? lastKnownLongitude;
  final bool medicalSummaryConsent;

  Map<String, dynamic> toJson() => {
    'clientRequestId': clientRequestId,
    'latitude': latitude,
    'longitude': longitude,
    'accuracyM': accuracyM,
    'lastKnown': {
      'latitude': lastKnownLatitude,
      'longitude': lastKnownLongitude,
    },
    'medicalSummaryConsent': medicalSummaryConsent,
  };

  factory QuickIncidentRequest.fromJson(Map<String, dynamic> json) {
    final lastKnown = json['lastKnown'] as Map<String, dynamic>? ?? {};
    return QuickIncidentRequest(
      clientRequestId: json['clientRequestId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyM: (json['accuracyM'] as num).toDouble(),
      lastKnownLatitude: (lastKnown['latitude'] as num?)?.toDouble(),
      lastKnownLongitude: (lastKnown['longitude'] as num?)?.toDouble(),
      medicalSummaryConsent: json['medicalSummaryConsent'] == true,
    );
  }
}

class QuickIncidentResult {
  const QuickIncidentResult({
    required this.incidentId,
    required this.duplicate,
  });

  final String incidentId;
  final bool duplicate;
}

class SafetyFunctionsRepository {
  SafetyFunctionsRepository({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final result = await _functions.httpsCallable(name).call(data);
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<QuickIncidentResult> submitQuickIncident(
    QuickIncidentRequest request,
  ) async {
    final data = await _call('submitQuickIncident', request.toJson());
    return QuickIncidentResult(
      incidentId: data['incidentId'] as String,
      duplicate: data['duplicate'] == true,
    );
  }

  Future<void> enrichIncident({
    required String incidentId,
    required String title,
    required String category,
    required String urgency,
    required String summary,
    required Map<String, dynamic> details,
    required List<String> mediaPaths,
  }) async {
    await _call('enrichIncident', {
      'incidentId': incidentId,
      'title': title,
      'category': category,
      'urgency': urgency,
      'summary': summary,
      'details': details,
      'mediaPaths': mediaPaths,
    });
  }

  Future<void> acceptIncident(String incidentId) =>
      _call('acceptIncident', {'incidentId': incidentId});

  Future<void> transitionStatus({
    required String incidentId,
    required String status,
    String note = '',
  }) => _call('transitionIncidentStatus', {
    'incidentId': incidentId,
    'status': status,
    'note': note,
  });

  Future<Map<String, dynamic>> getAssignedPrivate(String incidentId) =>
      _call('getAssignedIncidentPrivate', {'incidentId': incidentId});

  Future<Map<String, dynamic>> getMedicalSummary(String incidentId) =>
      _call('getEmergencyMedicalSummary', {'incidentId': incidentId});

  Future<void> followIncident(String incidentId, bool follow) =>
      _call('followIncident', {'incidentId': incidentId, 'follow': follow});

  Future<void> applyAsResponder({
    required String organization,
    required String identityNumberLast4,
    required List<String> evidencePaths,
  }) => _call('applyAsResponder', {
    'organization': organization,
    'identityNumberLast4': identityNumberLast4,
    'evidencePaths': evidencePaths,
  });

  Future<void> reviewResponder({
    required String uid,
    required String action,
    String reason = '',
  }) => _call('reviewResponderApplication', {
    'uid': uid,
    'action': action,
    'reason': reason,
  });

  Future<void> registerDevice({
    required String deviceId,
    required String token,
    required String platform,
    required String locale,
  }) => _call('registerDevice', {
    'deviceId': deviceId,
    'token': token,
    'platform': platform,
    'locale': locale,
    'enabled': true,
  });

  Future<Map<String, dynamic>> exportMyData() => _call('exportMyData', {});

  Future<void> deleteMyAccount() =>
      _call('deleteMyAccount', {'confirmation': 'DELETE'});
}
