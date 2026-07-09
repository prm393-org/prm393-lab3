import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../publication/domain/entities/work.dart';

class ResearchDashboardTopPapers extends StatelessWidget {
  final List<Work> papers;
  final ValueChanged<Work> onPaperTap;

  const ResearchDashboardTopPapers({
    super.key,
    required this.papers,
    required this.onPaperTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxCitations = papers.isEmpty ? 1 : papers.first.citedByCount;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    size: 19,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Influential Papers',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Citation impact within the loaded sample',
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
            const SizedBox(height: 12),
            for (var index = 0; index < papers.length; index++) ...[
              _PaperRow(
                rank: index + 1,
                paper: papers[index],
                maxCitations: maxCitations,
                onTap: () => onPaperTap(papers[index]),
              ),
              if (index != papers.length - 1)
                Divider(height: 1, color: cs.outlineVariant),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaperRow extends StatelessWidget {
  final int rank;
  final Work paper;
  final int maxCitations;
  final VoidCallback onTap;

  const _PaperRow({
    required this.rank,
    required this.paper,
    required this.maxCitations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final abstract = paper.abstract_?.trim();
    final progress = maxCitations <= 0
        ? 0.0
        : paper.citedByCount / maxCitations;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank == 1 ? cs.primary : cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: tt.labelMedium?.copyWith(
                  color: rank == 1 ? cs.onPrimary : cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    abstract == null || abstract.isEmpty
                        ? 'Abstract not available'
                        : abstract,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.56),
                      height: 1.35,
                      fontStyle: abstract == null || abstract.isEmpty
                          ? FontStyle.italic
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 9),
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          icon: Icons.format_quote,
                          label:
                              '${NumberFormatter.compact(paper.citedByCount)} citations',
                          color: cs.primary,
                          maxWidth: constraints.maxWidth,
                        ),
                        _MetaChip(
                          icon: Icons.calendar_today_outlined,
                          label:
                              paper.publicationYear?.toString() ?? 'Year N/A',
                          color: cs.onSurfaceVariant,
                          maxWidth: constraints.maxWidth,
                        ),
                        _MetaChip(
                          icon: Icons.library_books_outlined,
                          label: paper.sourceName?.trim().isNotEmpty ?? false
                              ? paper.sourceName!
                              : 'Unknown Journal',
                          color: cs.onSurfaceVariant,
                          maxWidth: constraints.maxWidth,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: progress,
                      color: cs.primary,
                      backgroundColor: cs.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double maxWidth;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
