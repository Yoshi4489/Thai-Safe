import 'package:flutter/material.dart';
import 'package:thai_safe/core/widgets/circle_decoration.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/images/ThaiSafe.jpg',
              height: 200,
              width: 200,
              )
            ),
            Text(
              "รวดเร็ว มั่นคง ปลอดภัย",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )
        ],
      ),
      bottomNavigationBar: CircleDecoration(),
    );
  }
}
