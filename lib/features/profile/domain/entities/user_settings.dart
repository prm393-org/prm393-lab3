import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../publication/domain/usecases/search_topics.dart';

/// Cấu hình người dùng lưu local (SharedPreferences).
class UserSettings extends Equatable {
  final String displayName;
  final String apiKey;
  final String mailto;
  final ThemeMode themeMode;
  final int perPage;
  final TopicSortFilter defaultHomeFilter;

  const UserSettings({
    this.displayName = 'Researcher',
    this.apiKey = '',
    this.mailto = '',
    this.themeMode = ThemeMode.system,
    this.perPage = 25,
    this.defaultHomeFilter = TopicSortFilter.popular,
  });

  UserSettings copyWith({
    String? displayName,
    String? apiKey,
    String? mailto,
    ThemeMode? themeMode,
    int? perPage,
    TopicSortFilter? defaultHomeFilter,
  }) =>
      UserSettings(
        displayName: displayName ?? this.displayName,
        apiKey: apiKey ?? this.apiKey,
        mailto: mailto ?? this.mailto,
        themeMode: themeMode ?? this.themeMode,
        perPage: perPage ?? this.perPage,
        defaultHomeFilter: defaultHomeFilter ?? this.defaultHomeFilter,
      );

  bool get hasApiKey => apiKey.trim().isNotEmpty;
  bool get hasMailto => mailto.trim().isNotEmpty;

  @override
  List<Object?> get props =>
      [displayName, apiKey, mailto, themeMode, perPage, defaultHomeFilter];
}
