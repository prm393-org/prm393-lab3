import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'features/profile/presentation/viewmodels/notification_center_viewmodel.dart';
import 'firebase/firebase_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Nạp biến môi trường (.env). Không bắt buộc có key — user nhập trong Settings.
  await dotenv.load(fileName: '.env').catchError((_) {});

  // SharedPreferences là dependency bất đồng bộ duy nhất; nạp ở đây rồi tiêm
  // vào Riverpod qua override, để mọi provider khác dựng được đồng bộ.
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  container.read(crashlyticsServiceProvider).registerGlobalHandlers();
  container.read(messagingServiceProvider).init();
  await container.read(remoteConfigServiceProvider).init();

  // Subscribe FCM ngay từ đầu: nếu đợi tới lúc mở màn Profile mới tạo provider
  // thì notification đến trước đó sẽ không lọt vào Notification Center.
  container.read(notificationCenterProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}
