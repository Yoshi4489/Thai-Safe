import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thai_safe/core/config/firebase.dart';
import 'package:thai_safe/core/services/app_bootstrap_service.dart';
import 'package:thai_safe/core/services/notification_service.dart';
import 'package:thai_safe/core/theme/app_theme.dart';
import 'package:thai_safe/features/app_shell.dart';
import 'package:thai_safe/features/authentication/presentation/auth_gate.dart';
import 'package:thai_safe/features/authentication/presentation/signup_otp_page.dart';
import 'package:thai_safe/features/authentication/presentation/signup_phone_page.dart';
import 'package:thai_safe/features/authentication/presentation/signup_profile_page.dart';
import 'package:thai_safe/features/incidents/services/incident_outbox_service.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Workmanager().initialize(incidentOutboxCallbackDispatcher);
  await AppBootstrapService.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
      title: 'Thai Safe',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {
        '/sign-up': (context) => SignupPhonePage(),
        '/sign-up-otp': (context) => SignupOtpPage(),
        '/sign-up-profile': (context) => SignupProfilePage(),
        '/app': (context) => const AppShell(),
      },
    );
  }
}
