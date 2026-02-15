import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thai_safe/core/validators/phone_validator.dart';
import 'package:thai_safe/features/authetication/presentation/widget/text_field_container.dart';
import 'package:thai_safe/features/authetication/providers/auth_state_provider.dart';

class SignupPage extends ConsumerWidget {
  SignupPage({super.key});
  final TextEditingController _telcontroller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      // ERROR
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }

      // OTP SENT SUCCESS
      if (next.verificationId != null && prev?.verificationId == null) {
        Navigator.pushNamed(context, '/sign-up-otp');
      }
    });

    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text(
              "Log In",
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.groups, size: 80, color: Colors.blue),
              Text(
                "ThaiSafe",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                  letterSpacing: 3,
                ),
              ),
              Text(
                "รวดเร็ว มั่นคง ปลอดภัย",
                style: GoogleFonts.sarabun(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 30),
              TextFieldContainer(
                child: TextField(
                  controller: _telcontroller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone),
                    hintText: "Telephone",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          final phone = _telcontroller.text.trim();
                          if (!PhoneValidator.isValidThaiPhone(phone)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "กรุณากรอกเบอร์โทรศัพท์ที่ถูกต้อง",
                                ),
                              ),
                            );
                            return;
                          }

                          final normalizedPhone = PhoneValidator.normalizeThaiPhone(phone);

                          await ref
                              .read(authControllerProvider.notifier)
                              .sendOtp(normalizedPhone);
                        },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(),
                  ),
                  child: authState.isLoading
                      ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white)
                      )
                      : Text("Sign Up"),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(thickness: 1)),
                  const SizedBox(width: 10),
                  Text("or sign up with"),
                  const SizedBox(width: 10),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 15),
              IconButton(
                onPressed: null,
                icon: Image.asset("assets/images/auth/ThaiID.png", height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
