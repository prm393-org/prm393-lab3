import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../publication/domain/entities/work.dart';

class WorkCard extends StatelessWidget {
  final Work work;
  final VoidCallback? onTap;

  const WorkCard({super.key, required this.work, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final authorText = _buildAuthorText();
    final yearSource = [
      if (work.publicationYear != null) work.publicationYear.toString(),
      if (work.sourceName != null) work.sourceName!,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                work.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (authorText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  authorText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              if (yearSource.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  yearSource,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: cs.primary),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _CitationBadge(count: work.citedByCount, cs: cs, tt: tt),
                  if (work.isOpenAccess) ...[
                    const SizedBox(width: 8),
                    _OaBadge(cs: cs),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildAuthorText() {
    if (work.authors.isEmpty) return '';
    const maxDisplay = 3;
    final names = work.authors
        .take(maxDisplay)
        .map((a) => a.displayName)
        .toList();
    final extra = work.authors.length - maxDisplay;
    if (extra > 0) return '${names.join(', ')} +$extra more';
    return names.join(', ');
  }
}

class _CitationBadge extends StatelessWidget {
  final int count;
  final ColorScheme cs;
  final TextTheme tt;
  const _CitationBadge({required this.count, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_quote, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            NumberFormatter.compact(count),
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _OaBadge extends StatelessWidget {
  final ColorScheme cs;
  const _OaBadge({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentTealBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Open Access',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.accentTealDark,
        ),
      ),
    );
  }
}
