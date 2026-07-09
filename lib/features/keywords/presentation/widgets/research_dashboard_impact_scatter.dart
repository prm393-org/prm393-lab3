import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../domain/entities/research_dashboard_summary.dart';

/// Scatter "Productivity vs Impact" dùng chung cho tác giả (#9) và tổ chức (#11):
/// trục X = số bài, trục Y = tổng trích dẫn (thang log). Bong bóng càng to =
/// càng nhiều citation. Góc trên-phải = vừa nhiều bài vừa nhiều ảnh hưởng.
class ResearchDashboardImpactScatter extends StatelessWidget {
  final List<ImpactStat> items;
  final String title;
  final String subjectNoun;
  final Color accent;

  const ResearchDashboardImpactScatter({
    super.key,
    required this.items,
    required this.title,
    required this.subjectNoun,
    this.accent = AppColors.tertiary,
  });

  double _log(num v) => math.log(v < 1 ? 1 : v) / math.ln10;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final pts = items.where((e) => e.papers > 0).toList();
    if (pts.length < 4) return const SizedBox.shrink();

    final maxPapers = pts.map((e) => e.papers).fold<int>(1, math.max);
    final maxCited = pts.map((e) => e.citations).fold<int>(1, math.max);

    final spots = <ScatterSpot>[];
    for (final e in pts) {
      final radius = (5 + (e.citations / maxCited) * 15).clamp(5.0, 20.0);
      spots.add(
        ScatterSpot(
          e.papers.toDouble(),
          _log(e.citations),
          dotPainter: FlDotCirclePainter(
            radius: radius,
            color: accent.withValues(alpha: 0.55),
            strokeColor: cs.surface,
            strokeWidth: 1.2,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.scatter_plot_outlined, size: 18, color: cs.primary),
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
            const SizedBox(height: 2),
            Text(
              'Each bubble is a$_an $subjectNoun · ${pts.length} in sample',
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: spots,
                  minX: 0,
                  maxX: maxPapers + 0.6,
                  minY: 0,
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipColor: (_) => cs.inverseSurface,
                      getTooltipItems: (spot) {
                        final idx = spots.indexWhere(
                            (s) => s.x == spot.x && s.y == spot.y);
                        if (idx < 0) return null;
                        final e = pts[idx];
                        return ScatterTooltipItem(
                          e.name,
                          textStyle: TextStyle(
                            color: cs.onInverseSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: '\n${e.papers} papers · '
                                  '${NumberFormatter.compact(e.citations)} citations',
                              style: TextStyle(
                                color:
                                    cs.onInverseSurface.withValues(alpha: 0.85),
                                fontWeight: FontWeight.normal,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('Citations',
                          style: TextStyle(
                              fontSize: 9,
                              color: cs.onSurface.withValues(alpha: 0.5))),
                      axisNameSize: 14,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (v, _) => Text(
                          NumberFormatter.compact(math.pow(10, v).round()),
                          style: TextStyle(
                              fontSize: 9,
                              color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text('Papers in sample',
                          style: TextStyle(
                              fontSize: 9,
                              color: cs.onSurface.withValues(alpha: 0.5))),
                      axisNameSize: 16,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          if (v != v.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            v.round().toString(),
                            style: TextStyle(
                                fontSize: 9,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 8, color: accent),
                const SizedBox(width: 4),
                Icon(Icons.circle, size: 14, color: accent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Top-right = prolific & highly cited · log scale',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // "a author" → "an author"; "a institution" → "an institution".
  String get _an =>
      'aeiou'.contains(subjectNoun.isEmpty ? '' : subjectNoun[0].toLowerCase())
          ? 'n'
          : '';
}
