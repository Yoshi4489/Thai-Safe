import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';
import 'package:thai_safe/features/incidents/services/incident_service.dart';

class IncidentState {
  const IncidentState({
    this.isLoading = false,
    this.error,
    this.incidents = const [],
    this.nearbyIncidents = const [],
    this.isRiskNearby = false,
  });

  final bool isLoading;
  final String? error;
  final List<IncidentModel> incidents;
  final List<IncidentModel> nearbyIncidents;
  final bool isRiskNearby;

  IncidentState copyWith({
    bool? isLoading,
    String? error,
    List<IncidentModel>? incidents,
    List<IncidentModel>? nearbyIncidents,
    bool? isRiskNearby,
  }) {
    return IncidentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      incidents: incidents ?? this.incidents,
      nearbyIncidents: nearbyIncidents ?? this.nearbyIncidents,
      isRiskNearby: isRiskNearby ?? this.isRiskNearby,
    );
  }
}

class IncidentController extends StateNotifier<IncidentState> {
  IncidentController(this._service) : super(const IncidentState()) {
    _subscription = _service.getIncidentsStream().listen(
      (incidents) => state = state.copyWith(incidents: incidents),
      onError: (Object error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  final IncidentService _service;
  StreamSubscription<List<IncidentModel>>? _subscription;

  Future<void> getIncidentsNearby(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final incidents = await _service
          .getIncidentsWithinKmRadius(latitude, longitude, radiusKm)
          .first;
      final risk = incidents.any(
        (incident) =>
            incident.status != 'cancelled' && incident.status != 'resolved',
      );
      state = state.copyWith(
        nearbyIncidents: incidents,
        isRiskNearby: risk,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString(), isLoading: false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final incidentServiceProvider = Provider<IncidentService>(
  (ref) => IncidentService(),
);

final incidentControllerProvider =
    StateNotifierProvider<IncidentController, IncidentState>((ref) {
      return IncidentController(ref.watch(incidentServiceProvider));
    });
