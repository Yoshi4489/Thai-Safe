import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/core/theme/app_theme.dart';
import 'package:thai_safe/features/authetication/presentation/login_page.dart';
import 'package:thai_safe/features/welcome/presentation/welcome_page.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thai Safe',
      theme: AppTheme.lightTheme,
      routes: {
        '/': (context) => WelcomePage(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}
