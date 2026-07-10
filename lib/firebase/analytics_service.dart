import 'package:firebase_analytics/firebase_analytics.dart';

/// Bọc Firebase Analytics. Đề bài yêu cầu đúng 7 event kèm parameter
/// (mục 4.1 phần Firebase) — gom hết vào đây thay vì rải
/// `FirebaseAnalytics.instance` khắp widget, để ViewModel gọi và test được.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// Gắn vào `MaterialApp.navigatorObservers` để tự log screen_view.
  FirebaseAnalyticsObserver get navigatorObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);

  Future<void> logLogin() => _analytics.logLogin(loginMethod: 'google');

  Future<void> logLogout() => _analytics.logEvent(name: 'logout');

  Future<void> logSearchTopic(String keyword) => _analytics.logEvent(
        name: 'search_topic',
        parameters: {'keyword': keyword},
      );

  Future<void> logViewPublication({
    required String title,
    required int? year,
  }) =>
      _analytics.logEvent(
        name: 'view_publication',
        parameters: {
          'publication_title': title,
          // Analytics không nhận null, và year của OpenAlex có thể thiếu.
          'publication_year': year ?? 0,
        },
      );

  Future<void> logViewJournal(String journalName) => _analytics.logEvent(
        name: 'view_journal',
        parameters: {'journal_name': journalName},
      );

  Future<void> logViewKeyword(String keyword) => _analytics.logEvent(
        name: 'view_keyword',
        parameters: {'keyword': keyword},
      );

  Future<void> logExportPdf(String topic) => _analytics.logEvent(
        name: 'export_pdf',
        parameters: {'topic': topic},
      );
}
