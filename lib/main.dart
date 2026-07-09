import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Nạp biến môi trường (.env). Không bắt buộc có key — user nhập trong Settings.
  await dotenv.load(fileName: '.env').catchError((_) {});

  // Cấu hình dependency injection (get_it).
  await configureDependencies();

  runApp(const App());
}
