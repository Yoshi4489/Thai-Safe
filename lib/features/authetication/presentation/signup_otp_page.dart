import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thai_safe/features/authetication/providers/auth_state_provider.dart';

class SignupOtpPage extends ConsumerStatefulWidget {
  const SignupOtpPage({super.key});

  @override
  ConsumerState<SignupOtpPage> createState() => _SignupOtpPageState();
}

class _SignupOtpPageState extends ConsumerState<SignupOtpPage> {
  final int otpLength = 6;
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;
  Timer? _timer;
  int _startSeconds = 120;

  @override
  void initState() {
    super.initState();

    controllers = List.generate(otpLength, (_) => TextEditingController());
    focusNodes = List.generate(otpLength, (_) => FocusNode());

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _startSeconds--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, "0");
    final s = (seconds % 60).toString().padLeft(2, "0");
    return "$m:$s";
  }

  String getOtp() => controllers.map((c) => c.text).join();

  @override
  void dispose() {
    _timer?.cancel();
    for (final f in focusNodes) f.dispose();
    for (final c in controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        return;
      }

      if (next.user == null) return;

      if (next.user!.firstLogin == true) {
        Navigator.pushReplacementNamed(context, "/sign-up-profile");
      } else {
        Navigator.pushReplacementNamed(context, "/app");
      }
    });

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/common/logo.jpg', height: 180),

            const SizedBox(height: 16),
            Text(
              "Enter OTP code",
              style: GoogleFonts.roboto(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              "OTP has been sent to ${authState.phoneNumber}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(otpLength, (index) {
                return SizedBox(
                  width: 48,
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < otpLength - 1) {
                        focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Time remaining: ${_formatTime(_startSeconds)}"),
                TextButton(
                  onPressed: _startSeconds == 0
                      ? () {
                          ref
                              .read(authControllerProvider.notifier)
                              .sendOtp(authState.phoneNumber!);
                          setState(() => _startSeconds = 120);
                          _startTimer();
                        }
                      : null,
                  child: const Text("Resend OTP"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () {
                        final otp = getOtp();
                        if (otp.length == otpLength) {
                          ref
                              .read(authControllerProvider.notifier)
                              .verifyOtp(otp);
                        }
                      },
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
