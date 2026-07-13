import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../firebase/firebase_providers.dart';
import '../../domain/entities/app_notification.dart';

/// Notification Center (FR 4.8): gom notification FCM nhận được trong phiên.
///
/// Provider này phải sống từ lúc khởi động (`main()` đọc nó một lần), nếu chờ
/// tới khi mở màn Profile mới subscribe thì các notification đến trước đó
/// đã trôi mất.
class NotificationCenterViewModel extends Notifier<List<AppNotification>> {
  static const int _maxItems = 30;

  @override
  List<AppNotification> build() {
    final messaging = ref.watch(messagingServiceProvider);

    final foreground = messaging.onMessage.listen(
      (message) => _add(message, inForeground: true),
    );
    final opened = messaging.onMessageOpenedApp.listen(
      (message) => _add(message, inForeground: false),
    );
    ref.onDispose(() {
      foreground.cancel();
      opened.cancel();
    });

    // Notification đã mở app từ trạng thái terminated.
    messaging.initialMessage.then((message) {
      if (message != null) _add(message, inForeground: false);
    });

    return const [];
  }

  void _add(RemoteMessage message, {required bool inForeground}) {
    if (!ref.mounted) return;
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Notification';
    final body = notification?.body ?? message.data['body'] ?? '';

    state = [
      AppNotification(
        title: title,
        body: body,
        receivedAt: DateTime.now(),
        receivedInForeground: inForeground,
      ),
      ...state,
    ].take(_maxItems).toList(growable: false);
  }

  void clear() => state = const [];
}

final notificationCenterProvider =
    NotifierProvider<NotificationCenterViewModel, List<AppNotification>>(
      NotificationCenterViewModel.new,
    );
