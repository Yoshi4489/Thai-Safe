import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/core/widgets/boot_loading_page.dart';
import 'package:thai_safe/features/app_shell.dart';
import 'package:thai_safe/features/authentication/presentation/signup_profile_page.dart';
import 'package:thai_safe/features/authentication/providers/auth_state_provider.dart';
import 'package:thai_safe/features/welcome/presentation/welcome_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    return authAsync.when(
      loading: () => const BootLoadingPage(),
      error: (e, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('เกิดข้อผิดพลาดในการตรวจสอบบัญชี'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(authStateProvider),
                child: Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return WelcomePage();
        }
        if (user.firstLogin == true) {
          return SignupProfilePage();
        }
        return AppShell();
      },
    );
  }
}
