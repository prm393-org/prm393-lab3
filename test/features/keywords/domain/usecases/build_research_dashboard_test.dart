import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/features/keywords/domain/usecases/build_research_dashboard.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/author.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/paged.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/topic.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';

void main() {
  const topic = Topic(
    id: 'https://openalex.org/T1',
    displayName: 'Machine Learning',
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
      authors: [
        Author(displayName: 'Ada'),
        Author(displayName: 'Lin'),
      ],
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

  test('aggregates KPI, rankings, trend, and top papers', () {
    const page = Paged<Work>(items: works, total: 120, page: 1, perPage: 100);

    final summary = const BuildResearchDashboard()(
      topic: topic,
      worksPage: page,
    );

    expect(summary.totalPublications, 120);
    expect(summary.totalCitations, 45);
    expect(summary.averageCitations, 15);
    expect(summary.mostActiveYear, 2024);
    expect(summary.topJournals.first.name, 'Journal A');
    expect(summary.topJournals.first.count, 2);
    expect(summary.topAuthors.first.name, 'Ada');
    expect(summary.topAuthors.first.count, 2);
    expect(summary.topPapers.first.id, 'W1');
    expect(
      summary.topJournals.any((item) => item.name == 'Unknown Journal'),
      isTrue,
    );
    expect(
      summary.topAuthors.any((item) => item.name == 'Unknown Author'),
      isTrue,
    );
  });
}
