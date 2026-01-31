import 'package:flutter/material.dart';

class WelcomePage2 extends StatelessWidget {
  const WelcomePage2({super.key});

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
            "assets/images/welcome/fireman.png",
            height: 300,
            width: 300,
          ),
          const Text(
            "รวดเร็ว",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.red
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "รับความช่วยเหลืออย่างรวดเร็วด้วยเทคโนโลยีระบุพิกัดตำแหน่ง",
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