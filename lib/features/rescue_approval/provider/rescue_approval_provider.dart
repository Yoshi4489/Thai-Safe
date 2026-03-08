import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:thai_safe/features/rescue_approval/data/resque_request_model.dart';
import 'package:thai_safe/features/rescue_approval/service/rescue_approval_service.dart';

class RescueApprovalState {
  final bool isLoading;
  final String? error;
  final List<RescueRequestModel> rescurerList;

  RescueApprovalState({
    this.isLoading = false,
    this.error = "",
    this.rescurerList = const [],
  });

  RescueApprovalState copyWith({
    bool? isLoading,
    String? error,
    List<RescueRequestModel>? rescurerList,
  }) {
    return RescueApprovalState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      rescurerList: rescurerList ?? this.rescurerList,
    );
  }
}

class RescueApprovalController extends StateNotifier<RescueApprovalState> {
  final RescueApprovalService _approvalService;

  RescueApprovalController(this._approvalService)
    : super(RescueApprovalState());

  Future<void> loadRescurerList() async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final list = await _approvalService.getRescueRequests().first;
      state = state.copyWith(rescurerList: list, error: "");
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final rescueApprovalService = Provider<RescueApprovalService>((ref) {
  return RescueApprovalService();
});

final rescueApprovalControllerProvider =
    StateNotifierProvider<RescueApprovalController, RescueApprovalState>((ref) {
      final service = ref.watch(rescueApprovalService);
      return RescueApprovalController(service)..loadRescurerList();
    });
