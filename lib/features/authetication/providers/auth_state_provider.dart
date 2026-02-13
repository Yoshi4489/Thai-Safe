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

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.verificationId,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    String? verificationId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      verificationId: verificationId ?? this.verificationId,
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
    state = state.copyWith(isLoading: true, error: null);

    await _authService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        state = state.copyWith(
          isLoading: false,
          verificationId: verificationId,
        );
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error,
        );
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

      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthController(authService);
});
