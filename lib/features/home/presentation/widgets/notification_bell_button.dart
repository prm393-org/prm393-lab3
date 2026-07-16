import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/widget_keys.dart';
import '../../../profile/presentation/viewmodels/notification_center_viewmodel.dart';
import '../../../profile/presentation/widgets/notification_center_sheet.dart';

/// Chuông góc phải Home: chấm đỏ khi còn notification chưa đọc.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(
      notificationCenterProvider.select((s) => s.hasUnread),
    );
    final cs = Theme.of(context).colorScheme;

    return IconButton(
      key: WidgetKeys.homeNotificationBell,
      tooltip: 'Notifications',
      onPressed: () => showNotificationCenterSheet(context),
      icon: Badge(
        isLabelVisible: hasUnread,
        smallSize: 8,
        backgroundColor: Colors.redAccent,
        child: Icon(
          hasUnread
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_outlined,
          color: cs.onSurface,
        ),
      ),
    );
  }
}
