import 'package:flutter/material.dart';

class SignUpPage1 extends StatefulWidget {
  const SignUpPage1({super.key});
  @override
  State<SignUpPage1> createState() => _SignUpPage1State();
}

class _SignUpPage1State extends State<SignUpPage1> {
  final TextEditingController _otpController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text("Please enter the OTP code sent to your phone.")
          ],
        ),
      ),
    );
  }
}
