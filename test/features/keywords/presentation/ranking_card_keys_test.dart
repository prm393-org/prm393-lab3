import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/constants/widget_keys.dart';
import 'package:journal_trend_analyzer/core/theme/app_colors.dart';
import 'package:journal_trend_analyzer/features/keywords/domain/entities/research_dashboard_summary.dart';
import 'package:journal_trend_analyzer/features/keywords/presentation/widgets/research_dashboard_ranking_card.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/keyword.dart';

/// Patrol TC7 tap vào dòng keyword trên dashboard để mở Keyword Detail.
/// Key nằm trong widget private lồng trong InkWell — nếu nó không tap được thì
/// test Patrol sẽ fail lúc chạy thật, nên chốt lại bằng widget test ở đây.
void main() {
  const items = [
    RankedResearchItem(
      name: 'deep learning',
      count: 30,
      keyword: Keyword(
        id: 'https://openalex.org/keywords/deep-learning',
        displayName: 'deep learning',
      ),
    ),
    RankedResearchItem(
      name: 'transformer',
      count: 12,
      keyword: Keyword(
        id: 'https://openalex.org/keywords/transformer',
        displayName: 'transformer',
      ),
    ),
  ];

  Future<void> pumpCard(
    WidgetTester tester, {
    ValueChanged<RankedResearchItem>? onItemTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResearchDashboardRankingCard(
            key: WidgetKeys.dashboardTopKeywords,
            title: 'Top Keywords',
            subtitle: 'Tap a keyword to open its detail',
            icon: Icons.sell_outlined,
            items: items,
            accent: AppColors.secondary,
            itemKeyBuilder: WidgetKeys.dashboardKeywordRow,
            onItemTap: onItemTap,
          ),
        ),
      ),
    );
  }

  testWidgets('exposes a key per keyword row for Patrol', (tester) async {
    await pumpCard(tester);

    expect(find.byKey(WidgetKeys.dashboardTopKeywords), findsOneWidget);
    expect(find.byKey(WidgetKeys.dashboardKeywordRow(0)), findsOneWidget);
    expect(find.byKey(WidgetKeys.dashboardKeywordRow(1)), findsOneWidget);
  });

  testWidgets('tapping a keyword row by key fires the callback', (tester) async {
    RankedResearchItem? tapped;
    await pumpCard(tester, onItemTap: (item) => tapped = item);

    await tester.tap(find.byKey(WidgetKeys.dashboardKeywordRow(1)));
    await tester.pump();

    // Phải trả về đúng dòng thứ 1, kèm Keyword để điều hướng sang detail.
    expect(tapped?.name, 'transformer');
    expect(tapped?.keyword?.filterId, 'keywords/transformer');
  });
}
