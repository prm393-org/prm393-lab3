import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../data/recent_searches_store.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';

/// Thay cho `get_it`: mọi dependency hạ tầng khai báo ở đây, và Riverpod lo
/// khởi tạo lười + cache. ViewModel lấy qua `ref.read(...)`.

/// [SharedPreferences] khởi tạo bất đồng bộ nên không dựng được trong provider
/// đồng bộ. `main()` phải override provider này trong `ProviderScope`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider phải được override trong ProviderScope.',
  ),
);

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final dioProvider = Provider<Dio>((ref) => Dio());

final recentSearchesStoreProvider = Provider<RecentSearchesStore>(
  (ref) => RecentSearchesStore(ref.watch(sharedPreferencesProvider)),
);

final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(ref.watch(connectivityProvider)),
);

/// Credentials nạp từ SharedPreferences khi tạo; màn Profile gọi
/// `setCredentials` để cập nhật khi user đổi API key.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(ref.watch(dioProvider));
  final prefs = ref.watch(sharedPreferencesProvider);

  final apiKey =
      prefs.getString(AppConstants.prefApiKey) ?? AppConfig.defaultApiKey;
  final mailto =
      prefs.getString(AppConstants.prefMailto) ?? AppConfig.defaultMailto;

  client.setCredentials(
    apiKey: apiKey.isEmpty ? null : apiKey,
    mailto: mailto.isEmpty ? null : mailto,
  );
  return client;
});
