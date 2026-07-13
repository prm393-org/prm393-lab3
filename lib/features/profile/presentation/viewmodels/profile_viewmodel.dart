import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../firebase/analytics_service.dart';
import '../../../../firebase/auth_service.dart';
import '../../../../firebase/crashlytics_service.dart';
import '../../../../firebase/firebase_providers.dart';
import '../../../../firebase/messaging_service.dart';
import '../../../../firebase/remote_config_service.dart';
import '../../../../firebase/storage_service.dart';
import '../../../keywords/domain/entities/research_dashboard_summary.dart';
import '../../../publication/domain/usecases/search_topics.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/build_report_pdf.dart';
import '../../providers/profile_providers.dart';
import 'profile_state.dart';

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // Nạp settings ngay khi provider được đọc lần đầu. Không await được trong
    // `build()` (phải trả state đồng bộ) nên đẩy sang microtask — theme hiển
    // thị mặc định đúng một frame rồi settle, y như hành vi cũ của `..load()`.
    Future.microtask(load);
    return const ProfileState();
  }

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);
  ApiClient get _apiClient => ref.read(apiClientProvider);
  AuthService get _auth => ref.read(authServiceProvider);
  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);
  CrashlyticsService get _crashlytics => ref.read(crashlyticsServiceProvider);
  MessagingService get _messaging => ref.read(messagingServiceProvider);
  RemoteConfigService get _remoteConfig => ref.read(remoteConfigServiceProvider);
  StorageService get _storage => ref.read(storageServiceProvider);
  BuildReportPdf get _buildReportPdf => ref.read(buildReportPdfProvider);

  Future<void> load() async {
    state = state.copyWith(status: ProfileStatus.loading, clearMessage: true);
    try {
      final settings = await _repository.loadSettings();
      _applyCredentials(settings);
      state = state.copyWith(status: ProfileStatus.loaded, settings: settings);
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        message: 'Could not load settings: $e',
      );
    }
    // Firebase không được chặn màn hình settings: chạy sau, lỗi thì bỏ qua.
    unawaited(loadFirebaseStatus());
  }

  /// Đọc trạng thái FCM + giá trị Remote Config đang áp dụng.
  Future<void> loadFirebaseStatus() async {
    readRemoteConfig();
    try {
      final granted = await _messaging.hasPermission();
      final token = granted ? await _messaging.getToken() : null;
      if (!ref.mounted) return;
      state = state.copyWith(notificationsGranted: granted, fcmToken: token);
    } catch (e, stack) {
      // Emulator không có Google Play Services sẽ ném ở đây — ghi nhận là
      // handled exception chứ không làm hỏng màn Profile.
      unawaited(
        _crashlytics
            .recordError(e, stack, reason: 'FCM status check failed')
            .catchError((_) {}),
      );
    }
  }

  /// FCM: xin quyền hiển thị notification (Android 13+ bật dialog hệ thống).
  Future<void> requestNotificationPermission() async {
    try {
      final granted = await _messaging.requestPermission();
      final token = granted ? await _messaging.getToken() : null;
      if (!ref.mounted) return;
      state = state.copyWith(
        notificationsGranted: granted,
        fcmToken: token,
        message: granted
            ? 'Notifications enabled'
            : 'Notification permission denied',
      );
    } catch (e, stack) {
      unawaited(
        _crashlytics
            .recordError(e, stack, reason: 'FCM permission request failed')
            .catchError((_) {}),
      );
      if (!ref.mounted) return;
      state = state.copyWith(message: 'Could not enable notifications: $e');
    }
  }

  /// Đọc giá trị Remote Config hiện tại vào state (đồng bộ, từ cache/default).
  void readRemoteConfig() {
    state = state.copyWith(
      remoteConfig: RemoteConfigValues(
        maxJournalsDisplayed: _remoteConfig.maxJournalsDisplayed,
        maxKeywordsDisplayed: _remoteConfig.maxKeywordsDisplayed,
      ),
    );
  }

  /// Fetch lại config từ console rồi cập nhật state.
  Future<void> refreshRemoteConfig() async {
    final activated = await _remoteConfig.refresh();
    if (!ref.mounted) return;
    readRemoteConfig();
    state = state.copyWith(
      message: activated
          ? 'Remote Config updated'
          : 'Remote Config unchanged (using cached values)',
    );
  }

  /// Crashlytics — non-fatal: app chạy tiếp, report lên console ở lần mở kế tiếp.
  Future<void> recordHandledException() async {
    try {
      throw StateError('Demo handled exception from Profile screen');
    } catch (e, stack) {
      await _crashlytics.recordError(
        e,
        stack,
        reason: 'Crashlytics demo — handled exception',
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        message: 'Handled exception recorded — check Crashlytics after restart',
      );
    }
  }

  /// Crashlytics — fatal: crash thật, không try/catch được.
  void testCrash() => _crashlytics.testCrash();

  /// Report Export: dựng PDF → upload Storage → giữ download URL trong state.
  Future<void> exportReport(ResearchDashboardSummary summary) async {
    final topic = summary.topic.displayName;
    state = state.copyWith(
      exportStatus: ReportExportStatus.generating,
      clearMessage: true,
    );
    try {
      final bytes = await _buildReportPdf(summary);
      if (!ref.mounted) return;

      state = state.copyWith(exportStatus: ReportExportStatus.uploading);
      final url = await _storage.uploadReportPdf(bytes: bytes, topic: topic);
      unawaited(_analytics.logExportPdf(topic).catchError((_) {}));
      if (!ref.mounted) return;

      state = state.copyWith(
        exportStatus: ReportExportStatus.done,
        reportUrl: url,
        message: 'Report uploaded to Firebase Storage',
      );
    } catch (e, stack) {
      unawaited(
        _crashlytics
            .recordError(e, stack, reason: 'PDF report export failed')
            .catchError((_) {}),
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        exportStatus: ReportExportStatus.error,
        message: 'Export failed: $e',
      );
    }
  }

  Future<void> save({
    required String displayName,
    required String apiKey,
    required String mailto,
  }) async {
    state = state.copyWith(status: ProfileStatus.saving, clearMessage: true);
    try {
      final settings = state.settings.copyWith(
        displayName:
            displayName.trim().isEmpty ? 'Researcher' : displayName.trim(),
        apiKey: apiKey.trim(),
        mailto: mailto.trim(),
      );
      await _repository.saveSettings(settings);
      _applyCredentials(settings);
      state = state.copyWith(
        status: ProfileStatus.saved,
        settings: settings,
        message: 'OpenAlex settings saved',
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        message: 'Save failed: $e',
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final settings = state.settings.copyWith(themeMode: mode);
    await _repository.saveSettings(settings);
    state = state.copyWith(settings: settings, clearMessage: true);
  }

  Future<void> setPerPage(int perPage) async {
    final settings = state.settings.copyWith(perPage: perPage);
    await _repository.saveSettings(settings);
    state = state.copyWith(settings: settings, clearMessage: true);
  }

  Future<void> setDefaultHomeFilter(TopicSortFilter filter) async {
    final settings = state.settings.copyWith(defaultHomeFilter: filter);
    await _repository.saveSettings(settings);
    state = state.copyWith(settings: settings, clearMessage: true);
  }

  Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(mode);
  }

  Future<void> resetSettings() async {
    state = state.copyWith(status: ProfileStatus.saving, clearMessage: true);
    try {
      await _repository.resetSettings();
      final settings = await _repository.loadSettings();
      _applyCredentials(settings);
      state = state.copyWith(
        status: ProfileStatus.saved,
        settings: settings,
        message: 'Settings restored to defaults',
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        message: 'Restore failed: $e',
      );
    }
  }

  /// Đăng xuất Firebase + Google; router redirect sẽ đẩy về `/login`.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      unawaited(_analytics.logLogout().catchError((_) {}));
      unawaited(_analytics.setUserId(null).catchError((_) {}));
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ProfileStatus.error,
        message: 'Sign out failed: $e',
      );
    }
  }

  void _applyCredentials(UserSettings settings) {
    _apiClient.setCredentials(
      apiKey: settings.apiKey.isEmpty ? null : settings.apiKey,
      mailto: settings.mailto.isEmpty ? null : settings.mailto,
    );
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
