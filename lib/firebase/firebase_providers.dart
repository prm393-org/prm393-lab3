import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';
import 'auth_service.dart';
import 'crashlytics_service.dart';
import 'local_notification_service.dart';
import 'messaging_service.dart';
import 'remote_config_service.dart';
import 'storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final analyticsServiceProvider =
    Provider<AnalyticsService>((ref) => AnalyticsService());

final crashlyticsServiceProvider =
    Provider<CrashlyticsService>((ref) => CrashlyticsService());

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

final messagingServiceProvider =
    Provider<MessagingService>((ref) => MessagingService());

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => LocalNotificationService(),
);

/// `init()` (nạp default + fetch nền) do `main()` gọi một lần trước `runApp`.
final remoteConfigServiceProvider =
    Provider<RemoteConfigService>((ref) => RemoteConfigService());

/// Nguồn sự thật cho trạng thái đăng nhập — router redirect và màn Profile
/// đều watch provider này thay vì tự gọi `FirebaseAuth.instance`.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);
