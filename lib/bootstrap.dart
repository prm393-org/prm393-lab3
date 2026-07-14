import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'features/profile/presentation/viewmodels/notification_center_viewmodel.dart';
import 'firebase/firebase_providers.dart';
import 'firebase_options.dart';

/// Khởi tạo dependency dùng chung cho `main()` và Patrol.
///
/// Patrol: KHÔNG gọi `WidgetsFlutterBinding.ensureInitialized()` /
/// `runApp()` / ghi đè `FlutterError.onError` (Crashlytics) trong test.
Future<Widget> createApp({bool enableCrashlyticsHandlers = false}) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await dotenv.load(fileName: '.env').catchError((_) {});

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  if (enableCrashlyticsHandlers) {
    container.read(crashlyticsServiceProvider).registerGlobalHandlers();
  }
  container.read(messagingServiceProvider).init();
  await container.read(remoteConfigServiceProvider).init();
  container.read(notificationCenterProvider);

  return UncontrolledProviderScope(
    container: container,
    child: const App(),
  );
}
