import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../publication/domain/usecases/search_topics.dart';
import '../../domain/entities/user_settings.dart';
abstract class ProfileLocalDatasource {
  Future<UserSettings> load();
  Future<void> save(UserSettings settings);
  Future<void> clear();
}

class ProfileLocalDatasourceImpl implements ProfileLocalDatasource {
  final SharedPreferences _prefs;

  ProfileLocalDatasourceImpl(this._prefs);

  @override
  Future<UserSettings> load() async {
    return UserSettings(
      displayName:
          _prefs.getString(AppConstants.prefDisplayName) ?? 'Researcher',
      apiKey: _prefs.getString(AppConstants.prefApiKey) ??
          AppConfig.defaultApiKey,
      mailto:
          _prefs.getString(AppConstants.prefMailto) ?? AppConfig.defaultMailto,
      themeMode: _themeFromString(_prefs.getString(AppConstants.prefThemeMode)),
      perPage: _prefs.getInt(AppConstants.prefPerPage) ??
          AppConstants.defaultPerPage,
      defaultHomeFilter: _filterFromString(
        _prefs.getString(AppConstants.prefDefaultHomeFilter),
      ),
    );
  }

  @override
  Future<void> save(UserSettings settings) async {
    await _prefs.setString(AppConstants.prefDisplayName, settings.displayName);
    await _prefs.setString(AppConstants.prefApiKey, settings.apiKey);
    await _prefs.setString(AppConstants.prefMailto, settings.mailto);
    await _prefs.setString(
      AppConstants.prefThemeMode,
      _themeToString(settings.themeMode),
    );
    await _prefs.setInt(AppConstants.prefPerPage, settings.perPage);
    await _prefs.setString(
      AppConstants.prefDefaultHomeFilter,
      settings.defaultHomeFilter.name,
    );
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(AppConstants.prefDisplayName);
    await _prefs.remove(AppConstants.prefApiKey);
    await _prefs.remove(AppConstants.prefMailto);
    await _prefs.remove(AppConstants.prefThemeMode);
    await _prefs.remove(AppConstants.prefPerPage);
    await _prefs.remove(AppConstants.prefDefaultHomeFilter);
  }

  static TopicSortFilter _filterFromString(String? raw) {
    if (raw == null) return TopicSortFilter.popular;
    return TopicSortFilter.values.asNameMap()[raw] ?? TopicSortFilter.popular;
  }

  static ThemeMode _themeFromString(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _themeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
