import 'package:flutter/material.dart';
import 'package:thai_safe/core/widgets/circle_decoration.dart';
import 'package:thai_safe/features/welcome/presentation/pages/welcome_page_1.dart';
import 'package:thai_safe/features/welcome/presentation/pages/welcome_page_2.dart';
import 'package:thai_safe/features/welcome/presentation/pages/welcome_page_3.dart';
import 'package:thai_safe/features/welcome/presentation/pages/welcome_page_4.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final int pageIndex = 0;
    final PageController pageController = PageController(initialPage: pageIndex);
    return Scaffold(
      body: PageView(
        scrollDirection: Axis.horizontal,
        controller: pageController,
        children: const <Widget>[
          WelcomePage1(),
          WelcomePage2(),
          WelcomePage3(),
          WelcomePage4()
        ],
      ),
      bottomNavigationBar: CircleDecoration(),
    );
  }
}
