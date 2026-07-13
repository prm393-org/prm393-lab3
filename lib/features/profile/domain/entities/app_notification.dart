import 'package:equatable/equatable.dart';

/// Một notification đã nhận, hiển thị trong Notification Center (FR 4.8).
class AppNotification extends Equatable {
  final String title;
  final String body;
  final DateTime receivedAt;

  /// True khi notification tới lúc app đang mở (foreground) — hệ điều hành
  /// không tự vẽ banner, nên Notification Center là nơi duy nhất thấy nó.
  final bool receivedInForeground;

  const AppNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
    this.receivedInForeground = true,
  });

  @override
  List<Object?> get props => [title, body, receivedAt, receivedInForeground];
}
