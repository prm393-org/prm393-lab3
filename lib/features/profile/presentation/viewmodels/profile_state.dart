import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/user_settings.dart';

enum ProfileStatus { initial, loading, loaded, saving, saved, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UserSettings settings;
  final String? message;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.settings = const UserSettings(),
    this.message,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    UserSettings? settings,
    String? message,
    bool clearMessage = false,
  }) =>
      ProfileState(
        status: status ?? this.status,
        settings: settings ?? this.settings,
        message: clearMessage ? null : (message ?? this.message),
      );

  ThemeMode get themeMode => settings.themeMode;

  @override
  List<Object?> get props => [status, settings, message];
}
