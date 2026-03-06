import 'package:flutter_riverpod/legacy.dart';
import 'package:thai_safe/features/admin/services/incidents_service.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';

class IncidentsState {
  final bool isLoading;
  final String error;
  final int totalIncidents;
  final int pendingIncidents;
  final int resolvedIncidents;
  final List<IncidentModel> recentIncidents;

 IncidentsState({
    this.isLoading = false,
    this.error = '',
    this.totalIncidents = 0,
    this.pendingIncidents = 0,
    this.resolvedIncidents = 0,
    this.recentIncidents = const [],
  });

 IncidentsState copyWith({
    bool? isLoading,
    String? error,
    int? totalIncidents,
    int? pendingIncidents,
    int? resolvedIncidents,
    List<IncidentModel>? recentIncidents,
  }) {
    return IncidentsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalIncidents: totalIncidents ?? this.totalIncidents,
      pendingIncidents: pendingIncidents ?? this.pendingIncidents,
      resolvedIncidents: resolvedIncidents ?? this.resolvedIncidents,
      recentIncidents: recentIncidents ?? this.recentIncidents,
    );
  }
}

class AdminIncidentContoller extends StateNotifier<IncidentsState> {
    final IncidentsService _incidentsService;

  AdminIncidentContoller(this._incidentsService) : super(IncidentsState());

  Future<void> loadIncidentsData() async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final total = await _incidentsService.getTotalIncidents();
      final pending = await _incidentsService.getIncidentsByStatus('pending');
      final resolved = await _incidentsService.getIncidentsByStatus('resolved');
    }   catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
