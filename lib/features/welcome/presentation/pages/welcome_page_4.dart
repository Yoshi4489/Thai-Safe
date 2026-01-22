import 'package:flutter/material.dart';

class WelcomePage4 extends StatelessWidget {
  const WelcomePage4({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/common/logo.jpg',
              height: 200,
              width: 200,
            ),
          ),
          Image.asset(
            "assets/images/welcome/rescue.png",
            height: 300,
            width: 300,
          ),
          const Text(
            "ปลอดภัย",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.green
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "ระบบรับความช่วยเหลือที่เสถียรออกแบบถูกต้องตามหลักวิศวกรรมดิจิทัล",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}