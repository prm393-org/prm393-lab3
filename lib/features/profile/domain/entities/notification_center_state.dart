import 'package:equatable/equatable.dart';

import 'app_notification.dart';

class NotificationCenterState extends Equatable {
  final List<AppNotification> items;
  final int unreadCount;

  const NotificationCenterState({
    this.items = const [],
    this.unreadCount = 0,
  });

  bool get hasUnread => unreadCount > 0;

  NotificationCenterState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
  }) => NotificationCenterState(
    items: items ?? this.items,
    unreadCount: unreadCount ?? this.unreadCount,
  );

  @override
  List<Object?> get props => [items, unreadCount];
}
