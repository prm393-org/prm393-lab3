import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/user_settings.dart';

enum ProfileStatus { initial, loading, loaded, saving, saved, error }

/// Tiến trình xuất báo cáo PDF (FR 4.8): dựng file → upload Storage → có URL.
enum ReportExportStatus { idle, generating, uploading, done, error }

/// Giá trị Remote Config đang áp dụng cho UI.
class RemoteConfigValues extends Equatable {
  final int maxJournalsDisplayed;
  final int maxKeywordsDisplayed;

  const RemoteConfigValues({
    this.maxJournalsDisplayed = 0,
    this.maxKeywordsDisplayed = 0,
  });

  @override
  List<Object?> get props => [maxJournalsDisplayed, maxKeywordsDisplayed];
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UserSettings settings;
  final String? message;

  /// FCM: đã được cấp quyền hiển thị notification chưa.
  final bool notificationsGranted;

  /// Token thiết bị — dán vào Firebase Console để gửi test notification.
  final String? fcmToken;

  final RemoteConfigValues remoteConfig;
  final ReportExportStatus exportStatus;

  /// Download URL của report vừa upload lên Storage.
  final String? reportUrl;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.settings = const UserSettings(),
    this.message,
    this.notificationsGranted = false,
    this.fcmToken,
    this.remoteConfig = const RemoteConfigValues(),
    this.exportStatus = ReportExportStatus.idle,
    this.reportUrl,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    UserSettings? settings,
    String? message,
    bool clearMessage = false,
    bool? notificationsGranted,
    String? fcmToken,
    RemoteConfigValues? remoteConfig,
    ReportExportStatus? exportStatus,
    String? reportUrl,
  }) => ProfileState(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    message: clearMessage ? null : (message ?? this.message),
    notificationsGranted: notificationsGranted ?? this.notificationsGranted,
    fcmToken: fcmToken ?? this.fcmToken,
    remoteConfig: remoteConfig ?? this.remoteConfig,
    exportStatus: exportStatus ?? this.exportStatus,
    reportUrl: reportUrl ?? this.reportUrl,
  );

  ThemeMode get themeMode => settings.themeMode;

  bool get isExporting =>
      exportStatus == ReportExportStatus.generating ||
      exportStatus == ReportExportStatus.uploading;

  @override
  List<Object?> get props => [
    status,
    settings,
    message,
    notificationsGranted,
    fcmToken,
    remoteConfig,
    exportStatus,
    reportUrl,
  ];
}
