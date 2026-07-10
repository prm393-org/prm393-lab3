import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Bọc Firebase Crashlytics (FR 4.8 — khối "Crashlytics Demo").
///
/// Crashlytics ghi crash xuống đĩa rồi mới upload ở **lần mở app kế tiếp**.
/// Nên sau khi bấm [testCrash], phải mở lại app thì report mới lên console.
class CrashlyticsService {
  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  /// Chuyển lỗi Flutter chưa bắt được và lỗi async của isolate vào Crashlytics.
  /// Gọi một lần trong `main()` sau `Firebase.initializeApp`.
  void registerGlobalHandlers() {
    FlutterError.onError = _crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> setUserIdentifier(String uid) =>
      _crashlytics.setUserIdentifier(uid);

  Future<void> log(String message) => _crashlytics.log(message);

  /// Handled exception — app vẫn chạy, report lên ở lần mở kế tiếp.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) =>
      _crashlytics.recordError(error, stack, reason: reason);

  /// Crash thật để demo. Ném ra ngoài main isolate nên không try/catch được.
  void testCrash() => _crashlytics.crash();
}
