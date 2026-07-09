import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/work_detail_navigation.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../domain/entities/work.dart';

class WorkCard extends StatelessWidget {
  final Work work;
  final VoidCallback? onTap;

  const WorkCard({super.key, required this.work, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () => openWorkDetail(context, work),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                work.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (work.publicationYear != null) ...[
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: cs.primary),
                    const SizedBox(width: 3),
                    Text(
                      '${work.publicationYear}',
                      style: tt.bodySmall?.copyWith(color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (work.sourceName != null) ...[
                    Icon(Icons.library_books_outlined,
                        size: 12,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        work.sourceName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.format_quote,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${NumberFormatter.compact(work.citedByCount)} citations',
                    style:
                        tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (work.isOpenAccess) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.3)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
