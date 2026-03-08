import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:thai_safe/features/incident_management/services/incident_management_service.dart';
import 'package:thai_safe/features/incidents/data/incident_model.dart';

class IncidentManagementState {
  final bool isLoading;
  final String error;
  final List<IncidentModel> incidents;

  IncidentManagementState({
    this.isLoading = false,
    this.error = '',
    this.incidents = const [],
  });

  IncidentManagementState copyWith({
    bool? isLoading,
    String? error,
    List<IncidentModel>? incidents
  }) {
    return IncidentManagementState(
      isLoading: isLoading ?? this.isLoading,
      error:  error ?? this.error,
      incidents: incidents ?? this.incidents
    );
  }
}

class IncidentManagementController extends StateNotifier<IncidentManagementState> {
  final IncidentManagementService _incidentManagementService;

  IncidentManagementController(this._incidentManagementService): super(IncidentManagementState());

  Future<void> loadIncidentByStatus(String status) async{
    state.copyWith(error: "", isLoading: false);
    try {
      
      state.copyWith(isLoading: null);
    } catch (e) {
      state.copyWith(error: e.toString(), isLoading: false);
    }
  }
} 

final incidentManagementController = Provider<IncidentManagementService>((ref) {
  return IncidentManagementService();
});
