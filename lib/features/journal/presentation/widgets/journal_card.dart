import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../publication/domain/entities/work.dart';

class JournalCard extends StatelessWidget {
  final Work work;
  final VoidCallback? onTap;

  const JournalCard({super.key, required this.work, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final snippet = _abstractSnippet();
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        work.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (yearSource.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          yearSource,
                          style: tt.bodySmall?.copyWith(color: cs.primary),
                        ),
                      ],
                      if (snippet != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          snippet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.format_quote,
                              size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            NumberFormatter.compact(work.citedByCount),
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          if (work.isOpenAccess) ...[
                            const SizedBox(width: 10),
                            const _OaTag(),
                          ],
                          const Spacer(),
                          Text(
                            'Read more',
                            style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward,
                              size: 12, color: cs.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _abstractSnippet() {
    final abs = work.abstract_;
    if (abs == null || abs.isEmpty) return null;
    return abs.length > 130 ? '${abs.substring(0, 130)}…' : abs;
  }
}

class _OaTag extends StatelessWidget {
  const _OaTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentTealBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'OA',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.accentTealDark,
        ),
      ),
    );
  }
}
