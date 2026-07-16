import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/widget_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';
import '../viewmodels/notification_center_viewmodel.dart';

Future<void> showNotificationCenterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => const NotificationCenterSheet(),
  );
}

class NotificationCenterSheet extends ConsumerStatefulWidget {
  const NotificationCenterSheet({super.key});

  @override
  ConsumerState<NotificationCenterSheet> createState() =>
      _NotificationCenterSheetState();
}

class _NotificationCenterSheetState
    extends ConsumerState<NotificationCenterSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationCenterProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationCenterProvider).items;

    return SafeArea(
      key: WidgetKeys.notificationCenterSheet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notification Center',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (items.isNotEmpty)
                  TextButton(
                    onPressed: ref
                        .read(notificationCenterProvider.notifier)
                        .clear,
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              key: WidgetKeys.notificationCenterEmpty,
              padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Text(
                'No notifications yet.\n\nSend one from Firebase Console '
                '(Messaging) using this device\'s FCM token.',
                textAlign: TextAlign.center,
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => _NotificationTile(item: items[i]),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(item.receivedAt).format(context);

    return ListTile(
      leading: Icon(
        item.receivedInForeground
            ? Icons.notifications_active_outlined
            : Icons.open_in_new,
        size: 20,
        color: AppColors.secondary,
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: item.body.isEmpty ? null : Text(item.body),
      trailing: Text(
        time,
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      ),
      isThreeLine: item.body.length > 40,
    );
  }
}
