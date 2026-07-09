import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../publication/domain/usecases/search_topics.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repository;
  final ApiClient _apiClient;

  ProfileCubit(this._repository, this._apiClient)
      : super(const ProfileState());

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearMessage: true));
    try {
      final settings = await _repository.loadSettings();
      _applyCredentials(settings);
      emit(state.copyWith(status: ProfileStatus.loaded, settings: settings));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        message: 'Could not load settings: $e',
      ));
    }
  }

  Future<void> save({
    required String displayName,
    required String apiKey,
    required String mailto,
  }) async {
    emit(state.copyWith(status: ProfileStatus.saving, clearMessage: true));
    try {
      final settings = state.settings.copyWith(
        displayName: displayName.trim().isEmpty ? 'Researcher' : displayName.trim(),
        apiKey: apiKey.trim(),
        mailto: mailto.trim(),
      );
      await _repository.saveSettings(settings);
      _applyCredentials(settings);
      emit(state.copyWith(
        status: ProfileStatus.saved,
        settings: settings,
        message: 'OpenAlex settings saved',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        message: 'Save failed: $e',
      ));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final settings = state.settings.copyWith(themeMode: mode);
    await _repository.saveSettings(settings);
    emit(state.copyWith(settings: settings, clearMessage: true));
  }

  Future<void> setPerPage(int perPage) async {
    final settings = state.settings.copyWith(perPage: perPage);
    await _repository.saveSettings(settings);
    emit(state.copyWith(settings: settings, clearMessage: true));
  }

  Future<void> setDefaultHomeFilter(TopicSortFilter filter) async {
    final settings = state.settings.copyWith(defaultHomeFilter: filter);
    await _repository.saveSettings(settings);
    emit(state.copyWith(settings: settings, clearMessage: true));
  }

  Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(mode);
  }

  Future<void> resetSettings() async {
    emit(state.copyWith(status: ProfileStatus.saving, clearMessage: true));
    try {
      await _repository.resetSettings();
      final settings = await _repository.loadSettings();
      _applyCredentials(settings);
      emit(state.copyWith(
        status: ProfileStatus.saved,
        settings: settings,
        message: 'Settings restored to defaults',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        message: 'Restore failed: $e',
      ));
    }
  }

  void _applyCredentials(UserSettings settings) {
    _apiClient.setCredentials(
      apiKey: settings.apiKey.isEmpty ? null : settings.apiKey,
      mailto: settings.mailto.isEmpty ? null : settings.mailto,
    );
  }
}
