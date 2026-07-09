import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDatasource _datasource;

  ProfileRepositoryImpl(this._datasource);

  @override
  Future<UserSettings> loadSettings() => _datasource.load();

  @override
  Future<void> saveSettings(UserSettings settings) =>
      _datasource.save(settings);

  @override
  Future<void> resetSettings() => _datasource.clear();
}
