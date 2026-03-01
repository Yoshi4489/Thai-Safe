import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:uuid/uuid.dart';

// Import Model และ Service 
import '../data/incident_model.dart';
import '../services/incident_service.dart';

// --- STATE ---
class IncidentState {
  final bool isLoading;
  final String? error;
  final List<IncidentModel> incidents;
  final List<IncidentModel> nearbyIncidents;
  final bool isRiskNearby;

  IncidentState({
    this.isLoading = false,
    this.error,
    this.incidents = const [],
    this.nearbyIncidents = const [],
    this.isRiskNearby = false,
  });

  IncidentState copyWith({
    bool? isLoading,
    String? error,
    List<IncidentModel>? incidents,
    List<IncidentModel>? nearbyIncidents,
    bool? isRiskNearby,
  }) {
    return IncidentState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // ส่ง null มาเพื่อล้างค่า error ได้
      incidents: incidents ?? this.incidents,
      nearbyIncidents: nearbyIncidents ?? this.nearbyIncidents,
      isRiskNearby: isRiskNearby ?? this.isRiskNearby,
    );
  }
}

// --- CONTROLLER ---
class IncidentController extends StateNotifier<IncidentState> {
  final IncidentService _service;
  final Ref _ref;

  IncidentController(this._service, this._ref) : super(IncidentState()) {
    _initData();
  }

  void _initData() {
    _service.getIncidentsStream().listen((incidentList) {
      if (mounted) {
        state = state.copyWith(incidents: incidentList);
      }
    }, onError: (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    });
  }

  Future<void> reportIncident({
    required String title,
    required String type,
    required Map<String, dynamic> details,
    required String urgency,
    required double lat,
    required double lng,
    required List<String>? imageUrls,
    required String userId,      
    required String reporterName, 
    required String reporterTel,  
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newId = const Uuid().v4();
      final geo = GeoFlutterFire();
      final point = geo.point(latitude: lat, longitude: lng);

      final incident = IncidentModel(
        id: newId,
        userId: userId,           
        reporterName: reporterName,
        reporterTel: reporterTel,
        title: title,
        type: type,
        details: details,
        latitude: lat,
        longitude: lng,
        geohash: point.hash,
        geopoint: point.geoPoint,
        status: 'Pending',
        urgency: urgency,
        createdAt: DateTime.now(),
        imageUrls: imageUrls ?? [],
      );

      // ส่งไป Service เพื่อบันทึกลง Database
      await _service.createIncident(incident);

      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      rethrow;
    }
  }

    Future<void> getIncidentsNearby(double userLat, double userLng, double radiusInKm) async {
      try {
        state = state.copyWith(isLoading: true);
        final nearbyIncidents = await _service.getIncidentsWithinKmRadius(userLat, userLng, radiusInKm).first;

        for (var incident in nearbyIncidents) {
          if (incident.status.toLowerCase() != 'cancelled' && incident.status.toLowerCase() != 'resolved') {
            state = state.copyWith(isRiskNearby: true);
            break;
          }
        }
        if (mounted) {
          state = state.copyWith(nearbyIncidents: nearbyIncidents, isLoading: false);
        }
      }
      catch (e) {
        if (mounted) {
          state = state.copyWith(error: e.toString(), isLoading: false);
        }
        rethrow;
      }
    }
}

// --- PROVIDERS ---
final incidentServiceProvider = Provider<IncidentService>((ref) {
  return IncidentService();
});

final incidentControllerProvider = StateNotifierProvider<IncidentController, IncidentState>((ref) {
  final service = ref.watch(incidentServiceProvider);
  return IncidentController(service, ref);
});