import 'package:flutter/material.dart';

class DotsIndicator extends StatefulWidget {
  final int currentIndex;
  const DotsIndicator({ super.key, required this.currentIndex });

  @override
  State<DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<DotsIndicator> {
  List<Color> dotColors = [Colors.yellow, Colors.red, Colors.blue, Colors.green];
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: widget.currentIndex == index ? 20 : 15,
          height: widget.currentIndex == index ? 20 : 15,
          decoration: BoxDecoration(
            color: widget.currentIndex == index ? dotColors[index] : Colors.grey,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
