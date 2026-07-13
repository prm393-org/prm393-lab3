import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/features/keywords/domain/usecases/build_keyword_detail.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/author.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/keyword.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/paged.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/trend_point.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';

void main() {
  const keyword = Keyword(
    id: 'https://openalex.org/keywords/machine-learning',
    displayName: 'Machine learning',
  );

  const works = [
    Work(
      id: 'W1',
      title: 'Paper One',
      publicationYear: 2023,
      citedByCount: 30,
      authors: [Author(displayName: 'Ada')],
      sourceName: 'Journal A',
      isOpenAccess: true,
    ),
    Work(
      id: 'W2',
      title: 'Paper Two',
      publicationYear: 2024,
      citedByCount: 10,
      authors: [Author(displayName: 'Ada'), Author(displayName: 'Lin')],
      sourceName: 'Journal A',
      isOpenAccess: false,
    ),
    Work(
      id: 'W3',
      title: 'Paper Three',
      publicationYear: 2024,
      citedByCount: 5,
      authors: [],
      isOpenAccess: false,
    ),
  ];

  const page = Paged<Work>(items: works, total: 900, page: 1, perPage: 100);

  test('aggregates KPI, journals, authors and publications from the sample', () {
    final summary = const BuildKeywordDetail()(
      keyword: keyword,
      worksPage: page,
      trend: const [],
    );

    // total đến từ meta.count, không phải kích thước mẫu.
    expect(summary.totalPublications, 900);
    expect(summary.sampleSize, 3);
    expect(summary.totalCitations, 45);
    expect(summary.averageCitations, 15);

    expect(summary.topJournals.first.name, 'Journal A');
    expect(summary.topJournals.first.count, 2);
    expect(summary.topAuthors.first.name, 'Ada');
    expect(summary.topAuthors.first.count, 2);

    // Bài không có tác giả vẫn được tính, gắn nhãn Unknown.
    expect(summary.topAuthors.any((a) => a.name == 'Unknown Author'), isTrue);
    expect(
      summary.topJournals.any((j) => j.name == 'Unknown Journal'),
      isTrue,
    );

    // Publications sắp giảm dần theo citation.
    expect(summary.publications.map((w) => w.id), ['W1', 'W2', 'W3']);
  });

  test('prefers the group_by trend over the sample-derived one', () {
    const apiTrend = [
      TrendPoint(year: 2020, count: 400),
      TrendPoint(year: 2021, count: 500),
    ];

    final summary = const BuildKeywordDetail()(
      keyword: keyword,
      worksPage: page,
      trend: apiTrend,
    );

    expect(summary.yearlyTrend, apiTrend);
    // mostActiveYear tính trên trend đầy đủ, không phải mẫu (2024).
    expect(summary.mostActiveYear, 2021);
  });

  test('falls back to a sample trend when the trend request failed', () {
    final summary = const BuildKeywordDetail()(
      keyword: keyword,
      worksPage: page,
      trend: const [],
    );

    expect(summary.yearlyTrend, [
      const TrendPoint(year: 2023, count: 1),
      const TrendPoint(year: 2024, count: 2),
    ]);
    expect(summary.mostActiveYear, 2024);
  });

  test('journalLimit caps the ranking (Remote Config drives it)', () {
    final summary = const BuildKeywordDetail()(
      keyword: keyword,
      worksPage: page,
      trend: const [],
      journalLimit: 1,
    );

    expect(summary.topJournals, hasLength(1));
  });
}
