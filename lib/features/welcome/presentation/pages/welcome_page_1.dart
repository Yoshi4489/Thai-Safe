import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage1 extends StatelessWidget {
  const WelcomePage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
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
                "รวดเร็ว มั่นคง ปลอดภัย",
                style: GoogleFonts.sarabun(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
      ),
    );
  }
}
