import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/core/config/firebase.dart';
import 'package:thai_safe/core/theme/app_theme.dart';
import 'package:thai_safe/features/app_shell.dart';
import 'package:thai_safe/features/authentication/presentation/auth_gate.dart';
import 'package:thai_safe/features/authentication/presentation/signup_otp_page.dart';
import 'package:thai_safe/features/authentication/presentation/signup_phone_page.dart';
import 'package:thai_safe/features/authentication/presentation/signup_profile_page.dart';
import 'package:thai_safe/features/welcome/presentation/welcome_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initFirebase();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thai Safe',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {
        '/sign-up': (context) => SignupPhonePage(),
        '/sign-up-otp': (context) => SignupOtpPage(),
        '/sign-up-profile': (context) => SignupProfilePage(),
        '/app': (context) => AppShell(), 
      },
    );
  }
}
