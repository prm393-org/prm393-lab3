import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../firebase/firebase_providers.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_center_state.dart';

/// Notification Center (FR 4.8): gom notification FCM nhận được trong phiên.
///
/// Provider này phải sống từ lúc khởi động (`main()` đọc nó một lần), nếu chờ
/// tới khi mở màn Profile mới subscribe thì các notification đến trước đó
/// đã trôi mất.
class NotificationCenterViewModel extends Notifier<NotificationCenterState> {
  static const int _maxItems = 30;

  @override
  NotificationCenterState build() {
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

    messaging.initialMessage.then((message) {
      if (message != null) _add(message, inForeground: false);
    });

    return const NotificationCenterState();
  }

  Future<void> _add(
    RemoteMessage message, {
    required bool inForeground,
  }) async {
    if (!ref.mounted) return;
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Notification';
    final body = notification?.body ?? message.data['body'] ?? '';

    // App đang mở: FCM không tự hiện khay — vẽ local notification.
    if (inForeground) {
      await ref
          .read(localNotificationServiceProvider)
          .show(title: title, body: body)
          .catchError((_) {});
    }

    if (!ref.mounted) return;
    state = state.copyWith(
      items: [
        AppNotification(
          title: title,
          body: body,
          receivedAt: DateTime.now(),
          receivedInForeground: inForeground,
        ),
        ...state.items,
      ].take(_maxItems).toList(growable: false),
      unreadCount: state.unreadCount + 1,
    );
  }

  void markAllRead() {
    if (state.unreadCount == 0) return;
    state = state.copyWith(unreadCount: 0);
  }

  void clear() => state = const NotificationCenterState();
}

final notificationCenterProvider =
    NotifierProvider<NotificationCenterViewModel, NotificationCenterState>(
      NotificationCenterViewModel.new,
    );
