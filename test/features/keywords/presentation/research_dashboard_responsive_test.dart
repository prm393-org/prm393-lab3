import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/features/keywords/domain/entities/research_dashboard_summary.dart';
import 'package:journal_trend_analyzer/features/keywords/presentation/widgets/research_dashboard_header.dart';
import 'package:journal_trend_analyzer/features/keywords/presentation/widgets/research_dashboard_kpi_grid.dart';
import 'package:journal_trend_analyzer/features/keywords/presentation/widgets/research_dashboard_ranking_card.dart';
import 'package:journal_trend_analyzer/features/keywords/presentation/widgets/research_dashboard_top_papers.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/author.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/topic.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/trend_point.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';
import 'package:journal_trend_analyzer/features/publication/presentation/widgets/trend_chart.dart';

void main() {
  for (final width in [360.0, 390.0]) {
    testWidgets('dashboard does not overflow at ${width.toInt()}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const ResearchDashboardHeader(summary: _summary),
                  const SizedBox(height: 16),
                  const ResearchDashboardKpiGrid(summary: _summary),
                  const SizedBox(height: 16),
                  const TrendChart(trend: _trend),
                  const ResearchDashboardTopPapers(
                    papers: _papers,
                    onPaperTap: _ignorePaper,
                  ),
                  const SizedBox(height: 16),
                  const ResearchDashboardRankingCard(
                    title: 'Top Journals',
                    subtitle: 'By publication frequency in the sample',
                    icon: Icons.library_books_outlined,
                    items: _rankings,
                    accent: Colors.indigo,
                  ),
                  const SizedBox(height: 16),
                  const ResearchDashboardRankingCard(
                    title: 'Top Authors',
                    subtitle: 'By contributing papers in the sample',
                    icon: Icons.groups_outlined,
                    items: _rankings,
                    accent: Colors.teal,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}

void _ignorePaper(Work _) {}

const _longName =
    'An exceptionally long multidisciplinary research journal and author name '
    'that must be truncated safely on narrow screens';

const _topic = Topic(
  id: 'T1',
  displayName:
      'A very long research topic title covering artificial intelligence, '
      'healthcare, climate science, and computational social systems',
  fieldName: _longName,
  domainName: _longName,
);

const _trend = [
  TrendPoint(year: 2020, count: 10),
  TrendPoint(year: 2021, count: 18),
  TrendPoint(year: 2022, count: 24),
  TrendPoint(year: 2023, count: 31),
  TrendPoint(year: 2024, count: 42),
];

const _rankings = [
  RankedResearchItem(name: _longName, count: 12),
  RankedResearchItem(name: 'Short name', count: 8),
];

const _papers = [
  Work(
    id: 'W1',
    title:
        'A very long paper title intended to verify that influential paper '
        'rows remain responsive without a RenderFlex overflow',
    publicationYear: 2024,
    citedByCount: 12345,
    authors: [Author(displayName: _longName)],
    sourceName: _longName,
    abstract_:
        'A deliberately long abstract that should be restricted to a small '
        'number of lines and end with an ellipsis on a narrow mobile display.',
    isOpenAccess: true,
  ),
];

const _summary = ResearchDashboardSummary(
  topic: _topic,
  totalPublications: 987654,
  totalCitations: 12345678,
  averageCitations: 1234.5,
  mostActiveYear: 2024,
  sampleSize: 100,
  yearlyTrend: _trend,
  citationTrend: _trend,
  topJournals: _rankings,
  topAuthors: _rankings,
  topKeywords: _rankings,
  topInstitutions: _rankings,
  authorStats: _impactStats,
  institutionStats: _impactStats,
  journalStats: _impactStats,
  emergingKeywords: _emergingKeywords,
  frontierKeywords: _frontierKeywords,
  topPapers: _papers,
  scatterPapers: _papers,
);

const _impactStats = [
  ImpactStat(name: 'Author A', papers: 5, citations: 1200),
  ImpactStat(name: 'Author B', papers: 4, citations: 980),
  ImpactStat(name: 'Author C', papers: 3, citations: 540),
  ImpactStat(name: 'Author D', papers: 2, citations: 210),
];

const _emergingKeywords = [
  KeywordSeries(keyword: 'kw a', points: _trend),
  KeywordSeries(keyword: 'kw b', points: _trend),
];

const _frontierKeywords = [
  KeywordFrontierPoint(keyword: 'kw a', meanYear: 2022, papers: 5, citations: 800),
  KeywordFrontierPoint(keyword: 'kw b', meanYear: 2021, papers: 4, citations: 600),
  KeywordFrontierPoint(keyword: 'kw c', meanYear: 2020, papers: 3, citations: 300),
  KeywordFrontierPoint(keyword: 'kw d', meanYear: 2019, papers: 2, citations: 120),
];
