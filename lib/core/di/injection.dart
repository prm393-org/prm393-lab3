import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../data/recent_searches_store.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../../features/profile/di/profile_di.dart';
import '../../features/publication/di/publication_di.dart';

/// Service locator toàn cục.
final GetIt getIt = GetIt.instance;

/// Đăng ký dependency hạ tầng (core). Mỗi feature tự đăng ký
/// datasource / repository / usecase / bloc của mình ở hàm riêng và
/// gọi tại đây (vd: `_initHome(getIt)`).
Future<void> configureDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<RecentSearchesStore>(
    () => RecentSearchesStore(getIt<SharedPreferences>()),
  );

  // Core
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<Connectivity>()),
  );
  getIt.registerLazySingleton<ApiClient>(() {
    final client = ApiClient(getIt<Dio>());
    final prefs = getIt<SharedPreferences>();
    final apiKey = prefs.getString(AppConstants.prefApiKey) ??
        AppConfig.defaultApiKey;
    final mailto =
        prefs.getString(AppConstants.prefMailto) ?? AppConfig.defaultMailto;
    client.setCredentials(
      apiKey: apiKey.isEmpty ? null : apiKey,
      mailto: mailto.isEmpty ? null : mailto,
    );
    return client;
  });

  // Features
  initProfileFeature(getIt);
  initPublicationFeature(getIt);
}
