import 'package:flutter/material.dart';

import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await createApp(enableCrashlyticsHandlers: true);
  runApp(app);
}
