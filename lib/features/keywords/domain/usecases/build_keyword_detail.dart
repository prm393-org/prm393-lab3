import '../../../publication/domain/entities/keyword.dart';
import '../../../publication/domain/entities/paged.dart';
import '../../../publication/domain/entities/trend_point.dart';
import '../../../publication/domain/entities/work.dart';
import '../aggregation.dart';
import '../entities/keyword_detail_summary.dart';

/// Gộp mẫu bài báo của một keyword thành dữ liệu cho màn Keyword Detail (4.7).
class BuildKeywordDetail {
  const BuildKeywordDetail();

  /// [trend] đến từ `group_by=publication_year` (toàn bộ keyword). Nếu gọi API
  /// trend lỗi thì truyền `const []` — hàm sẽ tự dựng trend từ mẫu để UI vẫn
  /// có biểu đồ thay vì trống trơn.
  KeywordDetailSummary call({
    required Keyword keyword,
    required Paged<Work> worksPage,
    required List<TrendPoint> trend,
    int journalLimit = 5,
    int authorLimit = 5,
    int publicationLimit = 10,
  }) {
    final works = worksPage.items;
    final totalCitations = works.fold<int>(0, (sum, w) => sum + w.citedByCount);

    final sampleYearCounts = <int, int>{};
    final journalCounts = <String, int>{};
    final authorCounts = <String, int>{};
    final authorCitations = <String, int>{};

    for (final work in works) {
      final year = work.publicationYear;
      if (year != null) {
        sampleYearCounts[year] = (sampleYearCounts[year] ?? 0) + 1;
      }

      final journal = safeName(work.sourceName, 'Unknown Journal');
      journalCounts[journal] = (journalCounts[journal] ?? 0) + 1;

      if (work.authors.isEmpty) {
        authorCounts['Unknown Author'] =
            (authorCounts['Unknown Author'] ?? 0) + 1;
        authorCitations['Unknown Author'] =
            (authorCitations['Unknown Author'] ?? 0) + work.citedByCount;
      } else {
        final authorsInWork = work.authors
            .map((a) => safeName(a.displayName, 'Unknown Author'))
            .toSet();
        for (final author in authorsInWork) {
          authorCounts[author] = (authorCounts[author] ?? 0) + 1;
          authorCitations[author] =
              (authorCitations[author] ?? 0) + work.citedByCount;
        }
      }
    }

    final yearlyTrend = trend.isNotEmpty
        ? trend
        : (sampleYearCounts.entries
              .map((e) => TrendPoint(year: e.key, count: e.value))
              .toList()
          ..sort((a, b) => a.year.compareTo(b.year)));

    final mostActiveYear = mostActiveYearOf({
      for (final point in yearlyTrend) point.year: point.count,
    });

    final publications = [...works]
      ..sort((a, b) {
        final byCitations = b.citedByCount.compareTo(a.citedByCount);
        if (byCitations != 0) return byCitations;
        return (b.publicationYear ?? 0).compareTo(a.publicationYear ?? 0);
      });

    return KeywordDetailSummary(
      keyword: keyword,
      totalPublications: worksPage.total,
      totalCitations: totalCitations,
      averageCitations: works.isEmpty ? 0 : totalCitations / works.length,
      sampleSize: works.length,
      mostActiveYear: mostActiveYear,
      yearlyTrend: yearlyTrend,
      topJournals: rankByCount(journalCounts, limit: journalLimit),
      topAuthors: rankByCount(authorCounts, limit: authorLimit),
      authorStats: impactStats(
        authorCounts,
        authorCitations,
      ).take(40).toList(growable: false),
      publications: publications
          .take(publicationLimit)
          .toList(growable: false),
    );
  }
}
