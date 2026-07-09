import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../publication/domain/entities/topic.dart';
import 'domain_palette.dart';

/// Xếp hạng các topic đang tải theo số bài báo (works_count).
///
/// Mỗi topic một dòng: tên đầy đủ + thanh tỉ lệ + số bài. Màu chấm = lĩnh vực
/// (domain). Đây là bản tóm tắt "top" phía trên danh sách topic đầy đủ — không
/// phải toàn cảnh tổng thể (Home tải topic theo trang).
class TopicChartsSection extends StatelessWidget {
  final List<Topic> topics;
  final ValueChanged<Topic> onSelect;

  /// Số dòng tối đa hiển thị trong phần tóm tắt.
  final int maxRows;

  const TopicChartsSection({
    super.key,
    required this.topics,
    required this.onSelect,
    this.maxRows = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final ranked = [...topics]
      ..sort((a, b) => b.worksCount.compareTo(a.worksCount));
    final shown = ranked.take(maxRows).toList();
    final maxV = shown
        .map((t) => t.worksCount)
        .fold<int>(1, (m, v) => v > m ? v : m);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Top topics by papers',
                    style:
                        tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final t in shown)
              _TopicBarRow(
                topic: t,
                maxValue: maxV,
                onTap: () => onSelect(t),
              ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Tap a topic to explore',
                style: tt.labelSmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicBarRow extends StatelessWidget {
  final Topic topic;
  final int maxValue;
  final VoidCallback onTap;

  const _TopicBarRow({
    required this.topic,
    required this.maxValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = DomainPalette.of(topic.domainName);
    final fraction = (topic.worksCount / maxValue).clamp(0.0, 1.0);

    return Semantics(
      button: true,
      label: '${topic.displayName}, '
          '${topic.worksCount} papers, ${topic.citedByCount} citations',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            topic.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            '${NumberFormatter.compact(topic.worksCount)} papers',
                            style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 7,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
