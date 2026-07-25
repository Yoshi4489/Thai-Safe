enum AppEnvironment { development, staging, production }

abstract final class EnvironmentConfig {
  static const raw = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get current => switch (raw) {
    'production' => AppEnvironment.production,
    'staging' => AppEnvironment.staging,
    _ => AppEnvironment.development,
  };

  static const firebaseProject = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'thai-safe-967b9',
  );

  static bool get isProduction => current == AppEnvironment.production;
}
