import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/features/publication/data/models/journal_summary_model.dart';
import 'package:journal_trend_analyzer/features/publication/data/models/work_model.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/journal_summary.dart';

void main() {
  group('JournalSummaryModel', () {
    test('maps OpenAlex source fields and preserves source ID', () {
      final model = JournalSummaryModel.fromJson(const {
        'id': 'https://openalex.org/S123',
        'display_name': 'IEEE Access',
        'issn_l': '2169-3536',
        'host_organization_name': 'IEEE',
        'works_count': 14203,
        'cited_by_count': 830000,
      });

      expect(model.id, 'https://openalex.org/S123');
      expect(model.shortId, 'S123');
      expect(model.displayName, 'IEEE Access');
      expect(model.issn, '2169-3536');
      expect(model.publisher, 'IEEE');
      expect(model.publicationCount, 14203);
      expect(model.citationCount, 830000);
    });

    test('handles missing optional fields without crashing', () {
      final model = JournalSummaryModel.fromJson(const {
        'id': 'https://openalex.org/S1',
      });

      expect(model.displayName, 'Unknown Source');
      expect(model.issn, isNull);
      expect(model.publisher, isNull);
      expect(model.publicationCount, 0);
      expect(model.citationCount, 0);
      expect(model.hasValidId, isTrue);
    });

    test('source without an ID is not navigable', () {
      final model = JournalSummaryModel.fromJson(const {});
      expect(model.displayName, 'Unknown Source');
      expect(model.hasValidId, isFalse);
    });
  });

  test('average citations is zero when publication count is zero', () {
    const journal = JournalSummary(
      id: 'https://openalex.org/S1',
      displayName: 'Journal',
      publicationCount: 0,
      citationCount: 12,
    );
    expect(journal.averageCitations, 0);
  });

  test('WorkModel preserves primary source ID', () {
    final work = WorkModel.fromJson(const {
      'id': 'https://openalex.org/W1',
      'title': 'Paper',
      'cited_by_count': 4,
      'primary_location': {
        'source': {
          'id': 'https://openalex.org/S99',
          'display_name': 'Journal 99',
        },
      },
    });
    expect(work.sourceId, 'https://openalex.org/S99');
    expect(work.sourceName, 'Journal 99');
  });
}
