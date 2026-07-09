import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../data/datasources/profile_local_datasource.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../domain/repositories/profile_repository.dart';
import '../presentation/cubit/profile_cubit.dart';

void initProfileFeature(GetIt sl) {
  if (sl.isRegistered<ProfileCubit>()) return;
  sl.registerLazySingleton<ProfileLocalDatasource>(
    () => ProfileLocalDatasourceImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileLocalDatasource>()),
  );
  sl.registerLazySingleton<ProfileCubit>(
    () => ProfileCubit(sl<ProfileRepository>(), sl<ApiClient>()),
  );
}

/// Gọi trước khi lấy [ProfileCubit] — hot reload không chạy lại [main].
void ensureProfileFeatureRegistered(GetIt sl) {
  if (sl.isRegistered<ProfileCubit>()) return;
  if (!sl.isRegistered<SharedPreferences>() || !sl.isRegistered<ApiClient>()) {
    throw StateError(
      'Dependencies not ready. Stop the app and run `flutter run` again.',
    );
  }
  initProfileFeature(sl);
}
