import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:thai_safe/features/profile/data/medical_profile_model.dart';
import 'package:thai_safe/features/profile/services/medical_profile_service.dart';

class MedicalProfileState {
  final bool isLoading;
  final String? error;
  final MedicalProfileModel? medicalProfile;

  MedicalProfileState({
    this.isLoading = false,
    this.error,
    this.medicalProfile
  });

  MedicalProfileState copyWith({
    bool? isLoading,
    String? error,
    MedicalProfileModel? medicalProfile
  }) {
    return MedicalProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      medicalProfile: medicalProfile ?? this.medicalProfile
    );
  }
}

class MedicalProfileController extends StateNotifier<MedicalProfileState> {
  final MedicalProfileService _medicalProfileService;
  StreamSubscription<MedicalProfileModel?>? _medicalProfileSubscription;

  MedicalProfileController(this._medicalProfileService) : super(MedicalProfileState()) {
    _medicalProfileSubscription = _medicalProfileService.medicalStateChange().listen((medicalData) {
      if (mounted) {
        state = state.copyWith(medicalProfile: medicalData);
      }
    });
  }
  
  Future<void> saveMedicalProfile(MedicalProfileModel profile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _medicalProfileService.updateMedicalProfile(profile.id, profile.toMap());
      
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }
}

final medicalProfileServiceProvider = Provider<MedicalProfileService>((ref) {
  return MedicalProfileService(); // สมมติว่าคุณสร้างไฟล์ Service ไว้แล้ว
});

final medicalProfileControllerProvider = StateNotifierProvider<MedicalProfileController, MedicalProfileState>((ref) {
  final service = ref.read(medicalProfileServiceProvider);
  return MedicalProfileController(service);
});