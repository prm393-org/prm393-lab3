import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/features/keywords/domain/entities/research_dashboard_summary.dart';
import 'package:journal_trend_analyzer/features/keywords/presentation/widgets/research_dashboard_emerging_keywords.dart';
import 'package:journal_trend_analyzer/features/keywords/presentation/widgets/research_dashboard_frontier.dart';
import 'package:journal_trend_analyzer/features/keywords/presentation/widgets/research_dashboard_impact_scatter.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/trend_point.dart';

/// Mẫu dữ liệu mỏng phải hiện thẻ "not enough data", không được biến mất —
/// nếu card tự ẩn, người dùng tưởng tính năng không tồn tại.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ListView(children: [child]))),
  );

  testWidgets('emerging keywords keeps its card when only one series', (
    tester,
  ) async {
    await pump(
      tester,
      const ResearchDashboardEmergingKeywords(
        series: [
          KeywordSeries(
            keyword: 'transformers',
            points: [
              TrendPoint(year: 2020, count: 1),
              TrendPoint(year: 2021, count: 3),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Emerging keywords'), findsOneWidget);
    expect(find.textContaining('Need at least two keywords'), findsOneWidget);
  });

  testWidgets('impact scatter keeps its card when under four points', (
    tester,
  ) async {
    await pump(
      tester,
      const ResearchDashboardImpactScatter(
        items: [
          ImpactStat(name: 'A', papers: 2, citations: 10),
          ImpactStat(name: 'B', papers: 1, citations: 4),
        ],
        title: 'Author Productivity vs Impact',
        subjectNoun: 'author',
      ),
    );

    expect(find.text('Author Productivity vs Impact'), findsOneWidget);
    expect(find.textContaining('at least four authors'), findsOneWidget);
  });

  testWidgets('research frontier keeps its card when under four keywords', (
    tester,
  ) async {
    await pump(
      tester,
      const ResearchDashboardFrontier(
        keywords: [
          KeywordFrontierPoint(
            keyword: 'bert',
            meanYear: 2020.5,
            papers: 3,
            citations: 40,
          ),
        ],
      ),
    );

    expect(find.text('Research frontier'), findsOneWidget);
    expect(
      find.textContaining('at least four recurring keywords'),
      findsOneWidget,
    );
  });
}
