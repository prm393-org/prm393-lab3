import 'package:flutter/material.dart';

import '../../../../core/constants/widget_keys.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../keywords/domain/entities/research_dashboard_summary.dart';

/// Sáu chỉ số dashboard Home mà FR 4.2 yêu cầu, theo đúng thứ tự đề bài.
///
/// Ô "Most influential publication" tap được → mở Publication Detail.
class HomeKpiGrid extends StatelessWidget {
  final ResearchDashboardSummary summary;
  final VoidCallback? onOpenMostInfluential;

  const HomeKpiGrid({
    super.key,
    required this.summary,
    this.onOpenMostInfluential,
  });

  @override
  Widget build(BuildContext context) {
    final influential = summary.mostInfluentialPublication;

    final cards = <_KpiData>[
      _KpiData(
        key: WidgetKeys.homeKpiTotalPublications,
        label: 'Total Publications',
        value: NumberFormatter.compact(summary.totalPublications),
        detail: 'OpenAlex result count',
        icon: Icons.description_outlined,
      ),
      _KpiData(
        key: WidgetKeys.homeKpiAverageCitations,
        label: 'Average Citations',
        value: summary.averageCitations.toStringAsFixed(1),
        detail: 'Per sampled paper',
        icon: Icons.analytics_outlined,
      ),
      _KpiData(
        key: WidgetKeys.homeKpiMostActiveYear,
        label: 'Most Active Year',
        value: summary.mostActiveYear?.toString() ?? 'N/A',
        detail: 'Peak sample volume',
        icon: Icons.calendar_month_outlined,
      ),
      _KpiData(
        key: WidgetKeys.homeKpiTopAuthor,
        label: 'Top Author',
        value: summary.topAuthor?.name ?? 'Unknown Author',
        detail: '${summary.topAuthor?.count ?? 0} sampled papers',
        icon: Icons.person_outline,
        isTextValue: true,
      ),
      _KpiData(
        key: WidgetKeys.homeKpiTopJournal,
        label: 'Top Journal',
        value: summary.topJournal?.name ?? 'Unknown Journal',
        detail: '${summary.topJournal?.count ?? 0} sampled papers',
        icon: Icons.library_books_outlined,
        isTextValue: true,
      ),
      _KpiData(
        key: WidgetKeys.homeKpiMostInfluential,
        label: 'Most Influential Publication',
        value: influential?.title ?? 'N/A',
        detail: influential == null
            ? 'No publication in sample'
            : '${NumberFormatter.compact(influential.citedByCount)} citations'
                  '${influential.publicationYear != null ? ' · ${influential.publicationYear}' : ''}',
        icon: Icons.workspace_premium_outlined,
        isTextValue: true,
        onTap: influential == null ? null : onOpenMostInfluential,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 320
            ? 2
            : 1;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: _KpiCard(data: card)),
          ],
        );
      },
    );
  }
}

class _KpiData {
  final Key key;
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final bool isTextValue;
  final VoidCallback? onTap;

  const _KpiData({
    required this.key,
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.isTextValue = false,
    this.onTap,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      key: data.key,
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.label,
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(data.icon, size: 16, color: cs.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                data.value,
                style: (data.isTextValue ? tt.titleMedium : tt.headlineSmall)
                    ?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                data.detail,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.52),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
