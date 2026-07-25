import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:thai_safe/core/services/notification_service.dart';
import 'package:thai_safe/features/authentication/data/user_model.dart';
import 'package:thai_safe/features/authentication/services/auth_service.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.verificationId,
    this.phoneNumber,
  });

  final bool isLoading;
  final UserModel? user;
  final String? error;
  final String? verificationId;
  final String? phoneNumber;

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

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authService) : super(const AuthState()) {
    _subscription = _authService.authStateChanges().listen(
      (user) {
        state = state.copyWith(user: user, isLoading: false);
        if (user != null && _notificationUid != user.id) {
          _notificationUid = user.id;
          unawaited(NotificationService.instance.initializeForSignedInUser());
        }
      },
      onError: (Object error) {
        state = state.copyWith(isLoading: false, error: error.toString());
      },
    );
  }

  final AuthService _authService;
  StreamSubscription<UserModel?>? _subscription;
  String? _notificationUid;

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

  Future<void> verifyOtp(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      state = state.copyWith(error: 'Please request a new OTP.');
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.verifyOtpAndLogin(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      state = state.copyWith(user: user, isLoading: false, error: null);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    DateTime? birthdate,
    String? gender,
    String? profile_url,
  }) async {
    final user = state.user;
    if (user == null) throw StateError('User not found');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = user.copyWith(
        firstName: firstName,
        lastName: lastName,
        birthdate: birthdate,
        gender: gender,
        profile_url: profile_url,
        firstLogin: false,
      );
      await _authService.updateUser(user.id, updated.toMap());
      state = state.copyWith(user: updated, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      rethrow;
    }
  }

  Future<void> refreshRoleClaims() => _authService.refreshRoleClaims();

  Future<void> logout() async {
    await _authService.logout();
    _notificationUid = null;
    state = const AuthState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.read(authServiceProvider));
  },
);

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});
