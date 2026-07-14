import 'package:flutter/material.dart';

/// Thẻ giữ chỗ cho biểu đồ khi mẫu dữ liệu quá mỏng để vẽ.
///
/// Trước đây các chart tự `SizedBox.shrink()` khi thiếu điểm dữ liệu — card biến
/// mất không dấu vết, người dùng (và người chấm) tưởng tính năng không tồn tại.
/// Giữ card lại kèm lý do thì rõ ràng hơn hẳn.
class ChartPlaceholderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const ChartPlaceholderCard({
    super.key,
    required this.title,
    required this.icon,
    this.message = 'Not enough data in this sample to plot this chart.',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
