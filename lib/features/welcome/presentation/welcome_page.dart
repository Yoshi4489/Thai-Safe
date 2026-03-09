import 'package:flutter/material.dart';
import 'package:thai_safe/features/welcome/presentation/pages/welcome_page_1.dart';
import 'package:thai_safe/features/welcome/presentation/pages/welcome_page_2.dart';
import 'package:thai_safe/features/welcome/presentation/pages/welcome_page_3.dart';
import 'package:thai_safe/features/welcome/presentation/pages/welcome_page_4.dart';
import 'package:thai_safe/features/welcome/presentation/widget/dots_indicator.dart';


class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int pageIndex = 0;
  late final PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/sign-up');
            },
            child: Text(
              pageIndex == 3 ? 'เริ่มต้นใช้งาน' : 'ข้าม',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),  
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: PageView(
              controller: pageController,
              onPageChanged: (index) {
                setState(() {
                  pageIndex = index;
                });
              },
              children: const [
                WelcomePage1(),
                WelcomePage2(),
                WelcomePage3(),
                WelcomePage4(),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: DotsIndicator(currentIndex: pageIndex),
          ),
        ],
      ),
    );
  }
}
