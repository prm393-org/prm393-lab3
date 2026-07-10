import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../publication/domain/usecases/search_topics.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/profile_repository.dart';
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

  void _applyCredentials(UserSettings settings) {
    _apiClient.setCredentials(
      apiKey: settings.apiKey.isEmpty ? null : settings.apiKey,
      mailto: settings.mailto.isEmpty ? null : settings.mailto,
    );
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
