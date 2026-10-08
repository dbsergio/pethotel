class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const int boardingStayDurationSeconds = int.fromEnvironment(
    'STAY_DURATION_SECONDS',
    defaultValue: 300, // 5 minutos por defecto
  );

  static const int pickupDelaySeconds = int.fromEnvironment(
    'PICKUP_DELAY_SECONDS',
    defaultValue: 15,
  );
}
