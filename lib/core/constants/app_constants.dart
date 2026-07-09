/// Hằng số dùng chung toàn app (OpenAlex API, default values).
///
/// Không hard-code dữ liệu học thuật ở đây — chỉ cấu hình endpoint/tham số.
class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'Journal Trend Analyzer';
  static const String appVersion = '1.0.0';

  // OpenAlex API
  static const String openAlexBaseUrl = 'https://api.openalex.org';
  static const String worksEndpoint = '/works';
  static const String topicsEndpoint = '/topics';

  // Pagination
  static const int defaultPerPage = 25;
  static const List<int> perPageOptions = [25, 50, 100];
  static const int maxPerPage = 100;

  // Network
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // SharedPreferences keys
  static const String prefDisplayName = 'pref_display_name';
  static const String prefApiKey = 'pref_api_key';
  static const String prefMailto = 'pref_mailto';
  static const String prefRecentSearches = 'pref_recent_searches';
  static const String prefSavedTopics = 'pref_saved_topics';
  static const String prefDefaultHomeFilter = 'pref_default_home_filter';
  static const String prefPerPage = 'pref_per_page';
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefLastSync = 'pref_last_sync';
}
