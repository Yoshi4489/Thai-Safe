import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:thai_safe/features/incident_management/services/incident_management_service.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';

class IncidentManagementState {
  final bool isLoading;
  final String error;
  final List<IncidentModel> pendingIncidents;
  final List<IncidentModel> acknowledgeIncidents;
  final List<IncidentModel> inProgressIncidents;
  final List<IncidentModel> resolvedIncidents;
  final List<IncidentModel> cancelledIncidents;

  IncidentManagementState({
    this.isLoading = false,
    this.error = '',
    this.pendingIncidents = const [],
    this.acknowledgeIncidents = const [],
    this.inProgressIncidents = const [],
    this.resolvedIncidents = const [],
    this.cancelledIncidents = const [],
  });

  IncidentManagementState copyWith({
    bool? isLoading,
    String? error,
    List<IncidentModel>? pendingIncidents,
    List<IncidentModel>? acknowledgeIncidents,
    List<IncidentModel>? inProgressIncidents,
    List<IncidentModel>? resolvedIncidents,
    List<IncidentModel>? cancelledIncidents,
  }) {
    return IncidentManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pendingIncidents: pendingIncidents ?? this.pendingIncidents,
      acknowledgeIncidents: acknowledgeIncidents ?? this.acknowledgeIncidents,
      inProgressIncidents: inProgressIncidents ?? this.inProgressIncidents,
      resolvedIncidents: resolvedIncidents ?? this.resolvedIncidents,
      cancelledIncidents: cancelledIncidents ?? this.cancelledIncidents,
    );
  }
}

class IncidentManagementController
    extends StateNotifier<IncidentManagementState> {
  final IncidentManagementService _incidentManagementService;

  IncidentManagementController(this._incidentManagementService)
    : super(IncidentManagementState());

  Future<void> loadIncidentByStatus(String status) async {
    state = state.copyWith(isLoading: true, error: "");

    try {
      final incidents = await _incidentManagementService
          .getIncidentByStatus(status)
          .first;

      switch (status) {
        case "Pending":
          state = state.copyWith(isLoading: false, pendingIncidents: incidents);
          break;
        case "Acknowledged":
          state = state.copyWith(
            isLoading: false,
            acknowledgeIncidents: incidents,
          );
          break;
        case "In Progress":
          state = state.copyWith(
            isLoading: false,
            inProgressIncidents: incidents,
          );
          break;
        case "Resolved":
          state = state.copyWith(
            isLoading: false,
            resolvedIncidents: incidents,
          );
          break;
        case "Cancelled":
          state = state.copyWith(
            isLoading: false,
            cancelledIncidents: incidents,
          );
          break;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final incidentManagementController = Provider<IncidentManagementService>((ref) {
  return IncidentManagementService();
});
