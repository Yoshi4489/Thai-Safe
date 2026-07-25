import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_safe/core/services/safety_functions_repository.dart';
import 'package:thai_safe/firebase_options.dart';
import 'package:uuid/uuid.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SafetyFunctionsRepository _repository = SafetyFunctionsRepository();

  Future<void> initializeForSignedInUser() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await _messaging.getToken();
    if (token != null) await _register(token);
    _messaging.onTokenRefresh.listen(_register);
  }

  Future<void> _register(String token) async {
    final preferences = await SharedPreferences.getInstance();
    var deviceId = preferences.getString('thai_safe_device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await preferences.setString('thai_safe_device_id', deviceId);
    }
    await _repository.registerDevice(
      deviceId: deviceId,
      token: token,
      platform: Platform.isAndroid ? 'android' : 'ios',
      locale: Platform.localeName,
    );
  }
}
