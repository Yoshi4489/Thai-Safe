import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/core/widgets/boot_loading_page.dart';
import 'package:thai_safe/features/admin/presentation/admin_page.dart';
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
      error: (e, stack) {
        // 1. ปริ้นท์ Error ลงใน Debug Console
        debugPrint('🔥 Auth Error: $e');
        debugPrint('🔥 Stack trace: $stack');

        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0), // เพิ่ม Padding ไม่ให้ตัวหนังสือชิดขอบจอเกินไป
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'เกิดข้อผิดพลาดในการตรวจสอบบัญชี',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. แสดง Error บนหน้าจอ (สีแดง)
                  Text(
                    'รายละเอียด: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.refresh(authStateProvider),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (user) {
        if (user == null) {
          return const WelcomePage();
        }
        if (user.firstLogin == true) {
          return const SignupProfilePage();
        }
        return const AppShell();
      },
    );
  }
}