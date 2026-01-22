import 'package:flutter/material.dart';

class CircleDecoration extends StatelessWidget {
  const CircleDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150, 
      width: 200, 
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0xFF4285F4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        
          Positioned(
            left: 100,
            bottom: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color.fromARGB(193, 52, 168, 83),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 180,
            bottom: 0,
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color.fromARGB(179, 234, 68, 53),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}