import 'package:firebase_analytics/firebase_analytics.dart';

/// Bọc Firebase Analytics. Đề bài yêu cầu đúng 7 event kèm parameter
/// (mục 4.1 phần Firebase) — gom hết vào đây thay vì rải
/// `FirebaseAnalytics.instance` khắp widget, để ViewModel gọi và test được.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance,
      _eventLogger = null;

  AnalyticsService.forTesting(
    Future<void> Function(String name, Map<String, Object>? parameters) logger,
  ) : _analytics = null,
      _eventLogger = logger;

  final FirebaseAnalytics? _analytics;
  final Future<void> Function(String name, Map<String, Object>? parameters)?
  _eventLogger;

  /// Gắn vào `MaterialApp.navigatorObservers` để tự log screen_view.
  FirebaseAnalyticsObserver get navigatorObserver => FirebaseAnalyticsObserver(
    analytics: _analytics ?? FirebaseAnalytics.instance,
  );

  Future<void> setUserId(String? uid) =>
      (_analytics ?? FirebaseAnalytics.instance).setUserId(id: uid);

  Future<void> logLogin() => (_analytics ?? FirebaseAnalytics.instance)
      .logLogin(loginMethod: 'google');

  Future<void> logLogout() => _logEvent('logout');

  Future<void> logSearchTopic(String keyword) =>
      _logEvent('search_topic', {'keyword': keyword});

  Future<void> logViewPublication({
    required String title,
    required int? year,
  }) => _logEvent('view_publication', {
    'publication_title': title,
    // Analytics không nhận null, và year của OpenAlex có thể thiếu.
    'publication_year': year ?? 0,
  });

  Future<void> logViewJournal({
    required String journalName,
    String? journalId,
  }) => _logEvent('view_journal', {
    'journal_name': journalName,
    if (journalId != null && journalId.isNotEmpty) 'journal_id': journalId,
  });

  Future<void> logViewKeyword(String keyword) =>
      _logEvent('view_keyword', {'keyword': keyword});

  Future<void> logExportPdf(String topic) =>
      _logEvent('export_pdf', {'topic': topic});

  Future<void> _logEvent(String name, [Map<String, Object>? parameters]) {
    final logger = _eventLogger;
    if (logger != null) return logger(name, parameters);
    return (_analytics ?? FirebaseAnalytics.instance).logEvent(
      name: name,
      parameters: parameters,
    );
  }
}
