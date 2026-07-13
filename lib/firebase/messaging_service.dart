import 'package:firebase_messaging/firebase_messaging.dart';

/// Handler chạy trong isolate riêng khi app ở background/terminated.
/// Bắt buộc là top-level function và có `@pragma('vm:entry-point')`,
/// nếu không tree-shaking của bản release sẽ loại bỏ nó.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Isolate này không dùng chung state với app; chỉ nên làm việc nhẹ.
}

/// Bọc Firebase Cloud Messaging (FR 4.8 — khối "Notification Center").
class MessagingService {
  MessagingService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  /// Notification nhận được khi app đang mở (foreground).
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Người dùng bấm vào notification để mở app từ background.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Notification đã mở app từ trạng thái terminated (nếu có).
  Future<RemoteMessage?> get initialMessage => _messaging.getInitialMessage();

  /// Xin quyền hiển thị notification. Trả về `true` nếu user đồng ý —
  /// map `AuthorizationStatus` ngay tại đây để ViewModel không phải import
  /// kiểu của plugin.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return _granted(settings);
  }

  /// Trạng thái quyền hiện tại, không bật dialog.
  Future<bool> hasPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return _granted(settings);
  }

  static bool _granted(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  /// Token của thiết bị — dán vào Firebase Console để gửi test notification.
  Future<String?> getToken() => _messaging.getToken();

  /// Chỉ đăng ký background handler. Cố tình **không** xin quyền ở đây:
  /// Android 13+ sẽ bật dialog POST_NOTIFICATIONS, mà hàm này chạy trước
  /// `runApp` — user sẽ thấy dialog trên nền màn hình trắng.
  /// Gọi [requestPermission] từ UI (màn Profile) thay vì lúc khởi động.
  void init() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}
