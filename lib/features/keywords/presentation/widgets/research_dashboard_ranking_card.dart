import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/research_dashboard_summary.dart';

class ResearchDashboardRankingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<RankedResearchItem> items;
  final Color accent;

  /// Cho phép tap từng dòng (bảng keyword → mở Keyword Detail). Bỏ trống thì
  /// thẻ chỉ để đọc, như bảng xếp hạng author/journal/institution.
  final ValueChanged<RankedResearchItem>? onItemTap;

  /// Cấp Key cho từng dòng để Patrol tap được đúng dòng thứ i.
  final Key Function(int index)? itemKeyBuilder;

  const ResearchDashboardRankingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.accent,
    this.onItemTap,
    this.itemKeyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxCount = items.isEmpty
        ? 1
        : items.map((item) => item.count).reduce((a, b) => a > b ? a : b);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface(accent),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: accent),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (var index = 0; index < items.length; index++) ...[
              KeyedSubtree(
                key: itemKeyBuilder?.call(index),
                child: _RankingRow(
                  item: items[index],
                  maxCount: maxCount,
                  accent: accent,
                  onTap: onItemTap == null
                      ? null
                      : () => onItemTap!(items[index]),
                ),
              ),
              if (index != items.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final RankedResearchItem item;
  final int maxCount;
  final Color accent;
  final VoidCallback? onTap;

  const _RankingRow({
    required this.item,
    required this.maxCount,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = maxCount == 0 ? 0.0 : item.count / maxCount;

    final row = Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            item.name,
            style: tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: onTap == null ? null : accent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 18,
              value: progress,
              color: accent,
              backgroundColor: AppColors.accentSurface(accent),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '${item.count}',
            textAlign: TextAlign.right,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right,
            size: 16,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
      ],
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}
