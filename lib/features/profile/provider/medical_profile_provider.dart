import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:thai_safe/features/profile/data/medical_profile_model.dart';
import 'package:thai_safe/features/profile/services/medical_profile_service.dart';

class MedicalProfileState {
  const MedicalProfileState({
    this.isLoading = false,
    this.error,
    this.medicalProfile,
  });

  final bool isLoading;
  final String? error;
  final MedicalProfileModel? medicalProfile;

  MedicalProfileState copyWith({
    bool? isLoading,
    String? error,
    MedicalProfileModel? medicalProfile,
  }) {
    return MedicalProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      medicalProfile: medicalProfile ?? this.medicalProfile,
    );
  }
}

class MedicalProfileController extends StateNotifier<MedicalProfileState> {
  MedicalProfileController(this._service) : super(const MedicalProfileState()) {
    _subscription = _service.medicalStateChange().listen(
      (profile) {
        state = state.copyWith(medicalProfile: profile, error: null);
      },
      onError: (Object error) {
        debugPrint('Medical profile stream error: $error');
        if (mounted) state = state.copyWith(error: error.toString());
      },
    );
  }

  final MedicalProfileService _service;
  StreamSubscription<MedicalProfileModel?>? _subscription;

  Future<void> saveMedicalProfile(MedicalProfileModel profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateMedicalProfile(profile.user_id, profile.toMap());
      if (mounted) state = state.copyWith(isLoading: false);
    } catch (error) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: error.toString());
      }
      rethrow;
    }
  }

  Future<void> createNewMedicalProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final profile = await _service.createMedicalProfile(userId);
    state = state.copyWith(isLoading: false, medicalProfile: profile);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final medicalProfileServiceProvider = Provider<MedicalProfileService>(
  (ref) => MedicalProfileService(),
);

final medicalProfileControllerProvider =
    StateNotifierProvider<MedicalProfileController, MedicalProfileState>((ref) {
      return MedicalProfileController(ref.read(medicalProfileServiceProvider));
    });
