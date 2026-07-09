import '../entities/user_settings.dart';

abstract class ProfileRepository {
  Future<UserSettings> loadSettings();
  Future<void> saveSettings(UserSettings settings);
  Future<void> resetSettings();
}
