import 'package:flutter/widgets.dart';

/// Key của các widget mà Patrol test cần chạm tới (Mục 8 của đề bài).
///
/// Gom vào một chỗ để test và UI dùng **chung một hằng số** — nếu đổi tên key,
/// compile sẽ báo lỗi ngay thay vì để test fail lúc chạy vì gõ sai chuỗi.
abstract final class WidgetKeys {
  WidgetKeys._();

  // ── Keyword Detail (FR 4.7 · Patrol TC7) ──────────────────────────
  static const keywordDetailScreen = Key('keyword_detail_screen');
  static const keywordDetailHeader = Key('keyword_detail_header');
  static const keywordDetailTrendChart = Key('keyword_detail_trend_chart');
  static const keywordDetailJournals = Key('keyword_detail_journals');
  static const keywordDetailAuthors = Key('keyword_detail_authors');
  static const keywordDetailAuthorChart = Key('keyword_detail_author_chart');
  static const keywordDetailPublications = Key(
    'keyword_detail_publications',
  );
  static const keywordDetailLoading = Key('keyword_detail_loading');
  static const keywordDetailError = Key('keyword_detail_error');
  static const keywordDetailEmpty = Key('keyword_detail_empty');

  /// Bài báo thứ [index] trong danh sách publication liên quan.
  static Key keywordDetailPublication(int index) =>
      Key('keyword_detail_publication_$index');

  // ── Research Dashboard (FR 4.6) ───────────────────────────────────
  static const dashboardTopKeywords = Key('dashboard_top_keywords');

  /// Dòng keyword thứ [index] trong bảng Top Keywords — TC7 tap vào đây để
  /// mở Keyword Detail.
  static Key dashboardKeywordRow(int index) => Key('dashboard_keyword_$index');

  // ── Profile · Notifications (FR 4.8 · FCM) ────────────────────────
  static const profileNotificationPermission = Key(
    'profile_notification_permission',
  );
  static const profileNotificationCenter = Key('profile_notification_center');
  static const profileFcmToken = Key('profile_fcm_token');
  static const notificationCenterSheet = Key('notification_center_sheet');
  static const notificationCenterEmpty = Key('notification_center_empty');

  // ── Profile · Remote Config (Patrol TC10) ─────────────────────────
  static const profileMaxJournals = Key('profile_max_journals_displayed');
  static const profileMaxKeywords = Key('profile_max_keywords_displayed');
  static const profileRemoteConfigRefresh = Key(
    'profile_remote_config_refresh',
  );

  // ── Profile · Report Export (Patrol TC9) ──────────────────────────
  static const profileExportPdf = Key('profile_export_pdf');
  static const profileReportUrl = Key('profile_report_url');
  static const profileCopyReportUrl = Key('profile_copy_report_url');

  // ── Profile · Crashlytics ─────────────────────────────────────────
  static const profileHandledException = Key('profile_handled_exception');
  static const profileTestCrash = Key('profile_test_crash');
}
