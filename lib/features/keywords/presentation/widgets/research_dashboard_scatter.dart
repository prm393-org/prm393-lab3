import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../publication/domain/entities/work.dart';
import 'chart_axis_utils.dart';

/// Scatter "Papers × Citations": mỗi bong bóng là một bài báo, đặt theo
/// năm xuất bản (trục X) và số trích dẫn (trục Y, thang log). Bong bóng
/// càng to = càng nhiều citation. Tap để mở chi tiết bài báo.
class ResearchDashboardScatter extends StatelessWidget {
  final List<Work> papers;
  final ValueChanged<Work> onPaperTap;

  const ResearchDashboardScatter({
    super.key,
    required this.papers,
    required this.onPaperTap,
  });

  double _log(num v) => math.log(v < 1 ? 1 : v) / math.ln10;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final pts = papers.where((w) => w.publicationYear != null).toList();
    if (pts.length < 4) return const SizedBox.shrink();

    final years = pts.map((w) => w.publicationYear!).toList();
    final minYear = years.reduce(math.min);
    final maxYear = years.reduce(math.max);
    final maxCited =
        pts.map((w) => w.citedByCount).fold<int>(1, math.max).toDouble();
    // Trục Y log: trần là một "thập kỷ" tròn để nhãn 1/10/100/1K/10K gọn.
    final maxLogY =
        (math.log(maxCited) / math.ln10).ceilToDouble().clamp(1.0, 9.0);
    final yearStep = yearAxisStep(maxYear - minYear);

    final spots = <ScatterSpot>[];
    for (final w in pts) {
      final radius =
          (5 + (w.citedByCount / maxCited) * 15).clamp(5.0, 20.0);
      spots.add(
        ScatterSpot(
          w.publicationYear!.toDouble(),
          _log(w.citedByCount),
          dotPainter: FlDotCirclePainter(
            radius: radius,
            color: AppColors.tertiary.withValues(alpha: 0.55),
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
                Icon(Icons.bubble_chart_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Papers × Citations',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Each bubble is a paper · ${pts.length} of sample',
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
                  minX: minYear - 0.6,
                  maxX: maxYear + 0.6,
                  minY: 0,
                  maxY: maxLogY,
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipColor: (_) => cs.inverseSurface,
                      getTooltipItems: (spot) {
                        final idx = spots.indexWhere(
                            (s) => s.x == spot.x && s.y == spot.y);
                        if (idx < 0) return null;
                        final w = pts[idx];
                        return ScatterTooltipItem(
                          w.title,
                          textStyle: TextStyle(
                            color: cs.onInverseSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: '\n${w.publicationYear} · '
                                  '${NumberFormatter.compact(w.citedByCount)} citations',
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
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final idx = response?.touchedSpot?.spotIndex;
                      if (idx != null && idx >= 0 && idx < pts.length) {
                        onPaperTap(pts[idx]);
                      }
                    },
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
                        reservedSize: 34,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          // Chỉ nhãn ở giá trị log nguyên (1/10/100/1K/10K).
                          if ((v - v.round()).abs() > 0.01) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            NumberFormatter.compact(math.pow(10, v).round()),
                            style: TextStyle(
                                fontSize: 9,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text('Publication year',
                          style: TextStyle(
                              fontSize: 9,
                              color: cs.onSurface.withValues(alpha: 0.5))),
                      axisNameSize: 16,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: yearStep.toDouble(),
                        getTitlesWidget: (v, _) => yearAxisLabel(
                          v,
                          minYear,
                          yearStep,
                          cs.onSurface.withValues(alpha: 0.5),
                        ),
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
                Icon(Icons.circle, size: 8, color: AppColors.tertiary),
                const SizedBox(width: 4),
                Icon(Icons.circle, size: 14, color: AppColors.tertiary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Larger bubble = more cited · tap to open · log scale',
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
}
