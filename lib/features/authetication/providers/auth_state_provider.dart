import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:thai_safe/features/authetication/data/user_model.dart';
import 'package:thai_safe/features/authetication/services/auth_service.dart';

/// =======================
/// STATE
/// =======================
class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final String? verificationId;
  final String? phoneNumber;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.verificationId,
    this.phoneNumber,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    String? verificationId,
    String? phoneNumber,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

/// =======================
/// CONTROLLER
/// =======================
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(AuthState());

  /* -----------------------
   * SEND OTP
   * ----------------------- */
  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      phoneNumber: phoneNumber,
    );

    await _authService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        state = state.copyWith(
          isLoading: false,
          verificationId: verificationId,
        );
      },
      onError: (error) {
        state = state.copyWith(isLoading: false, error: error);
      },
    );
  }

  /* -----------------------
   * VERIFY OTP
   * ----------------------- */
  Future<void> verifyOtp(String smsCode) async {
    final verificationId = state.verificationId;

    if (verificationId == null) {
      state = state.copyWith(
        error: 'Verification ID not found. Please request OTP again.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.verifyOtpAndLogin(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      state = state.copyWith(user: user, error: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /* -----------------------
   * UPDATE PROFILE
   * ----------------------- */
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    int? age,
    String? gender
  }) async {
    final user = state.user;

    if (user == null) {
      state = state.copyWith(error: "User not found");
      return Future.error("User not found");
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedUser = user.copyWith(
        firstName: firstName ?? user.firstName,
        lastName: lastName ?? user.lastName,
        age: age ?? user.age,
        gender: gender ?? user.gender,
        firstLogin: false,
      );

      state = state.copyWith(user: updatedUser, isLoading: false);
      _authService.updateUser(user.id, updatedUser.toMap());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /* -----------------------
   * LOGOUT
   * ----------------------- */
  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}

/// =======================
/// PROVIDERS
/// =======================

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authService = ref.read(authServiceProvider);
    return AuthController(authService);
  },
);
