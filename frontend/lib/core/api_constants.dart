/// Centralized API configuration for the Safe Kid App client.
///
/// The base URL can be overridden at build/run time:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
///
/// Android emulators cannot reach the host machine through 127.0.0.1, so use
/// `--dart-define=API_BASE_URL=http://10.0.2.2:8000` when running on Android.
class ApiConstants {
  const ApiConstants._();

  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  /// Every application endpoint lives under this prefix.
  static const String apiPrefix = '/api';

  static const Duration requestTimeout = Duration(seconds: 20);

  // System
  static const String health = '$apiPrefix/health';

  // Authentication
  static const String register = '$apiPrefix/auth/register';
  static const String login = '$apiPrefix/auth/login';
  static const String currentUser = '$apiPrefix/auth/me';

  // Children
  static const String children = '$apiPrefix/children';

  static String child(int childId) => '$children/$childId';

  // Analysis
  static const String analyze = '$apiPrefix/analyze';

  // Messages
  static const String messages = '$apiPrefix/messages';
  static const String messagesUpload = '$messages/upload';

  // Dashboard
  static const String dashboardStats = '$apiPrefix/dashboard/stats';

  // Reports
  static const String reportsExport = '$apiPrefix/reports/export';

  // Alerts
  static const String alerts = '$apiPrefix/alerts';
  static const String unreadAlertsCount = '$alerts/unread-count';

  static String markAlertRead(int alertId) => '$alerts/$alertId/read';
}
