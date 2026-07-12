import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../publication/domain/entities/journal_summary.dart';

class JournalCard extends StatelessWidget {
  final JournalSummary journal;
  final int rank;
  final VoidCallback? onTap;

  const JournalCard({
    super.key,
    required this.journal,
    required this.rank,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      label:
          'Rank $rank, ${journal.displayName}, ${journal.publicationCount} publications, ${journal.citationCount} citations, average ${journal.averageCitations.toStringAsFixed(1)} citations',
      child: Card(
        color: rank == 1 ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      rank.toString().padLeft(2, '0'),
                      style: textTheme.labelLarge?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          journal.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${NumberFormatter.compact(journal.publicationCount)} papers · ${NumberFormatter.compact(journal.citationCount)} citations${journal.isCitationEstimate ? '*' : ''}',
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Avg ${journal.averageCitations.toStringAsFixed(1)} citations${journal.isCitationEstimate ? '*' : ''}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
