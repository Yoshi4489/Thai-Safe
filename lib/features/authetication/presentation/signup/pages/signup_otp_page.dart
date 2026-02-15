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

  void startCountDownTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (_startSeconds == 0) {
        setState(() {
          timer.cancel();
        });
      }
      else {
        setState(() {
          _startSeconds--;
        });
      }
    });
  }

  void restartTimer() {
    _timer?.cancel();
    setState(() {
      _startSeconds = 120;
    });
    startCountDownTimer();
  }

  String _formatTime(int seconds) {
    Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }


  String getOtp() {
    return controllers.map((c) => c.text).join();
  }

  @override
  void initState() {
    super.initState();
    controllers = List.generate(otpLength, (_) => TextEditingController());
    focusNodes = List.generate(otpLength, (_) => FocusNode());
    startCountDownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final c in focusNodes) {
      c.dispose();
    }

    for (final t in controllers) {
      t.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null || prev?.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${next.error}"))
        );
        return;
      }
      else {
        print("Success");
      }
    });
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/common/logo.jpg',
                height: 200,
                width: 200,
              ),
              Text(
                "Enter OTP code",
                style: GoogleFonts.roboto(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              Text(
                "OTP has been sent to ${authState.phoneNumber}",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(otpLength, (index) {
                  return SizedBox(
                    width: 50,
                    child: TextField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty && index > 0) {
                          FocusScope.of(context)
                              .requestFocus(focusNodes[index - 1]);
                        }
                        if (value.isNotEmpty && index < otpLength - 1) {
                          FocusScope.of(context)
                              .requestFocus(focusNodes[index + 1]);
                        }
                      },
                    ),
                  );
                }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Time Remaining : ${_formatTime(_startSeconds)}"),
                  TextButton(
                    onPressed: () {
                      if (_startSeconds == 0) {
                        ref.read(authControllerProvider.notifier).sendOtp(authState.phoneNumber!);
                      }
                    },
                    child: Text(
                      "Resend OTP",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading
                  ? null
                  : () {
                    String otp = getOtp();
                    final verificationId = authState.verificationId;
                    if (otp.length == otpLength && verificationId != null && !authState.isLoading) {
                      ref.read(authControllerProvider.notifier).verifyOtp(otp);
                    }
                  },
                  child: authState.isLoading
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator()
                  )
                  : Text("Verify"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
