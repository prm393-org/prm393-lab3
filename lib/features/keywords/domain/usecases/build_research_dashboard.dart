import '../../../publication/domain/entities/paged.dart';
import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/entities/trend_point.dart';
import '../../../publication/domain/entities/work.dart';
import '../entities/research_dashboard_summary.dart';

class BuildResearchDashboard {
  const BuildResearchDashboard();

  ResearchDashboardSummary call({
    required Topic topic,
    required Paged<Work> worksPage,
  }) {
    final works = worksPage.items;
    final totalCitations = works.fold<int>(
      0,
      (sum, work) => sum + work.citedByCount,
    );

    final yearCounts = <int, int>{};
    final citationByYear = <int, int>{};
    final journalCounts = <String, int>{};
    final journalCitations = <String, int>{};
    final authorCounts = <String, int>{};
    final authorCitations = <String, int>{};
    final keywordCounts = <String, int>{};
    final keywordCitations = <String, int>{};
    final keywordYearCounts = <String, Map<int, int>>{}; // kw -> {năm: số bài}
    final keywordYearSum = <String, int>{}; // kw -> tổng năm (cho năm TB)
    final keywordYearOccur = <String, int>{}; // kw -> số bài có năm
    final institutionCounts = <String, int>{};
    final institutionCitations = <String, int>{};

    for (final work in works) {
      final year = work.publicationYear;
      if (year != null) {
        yearCounts[year] = (yearCounts[year] ?? 0) + 1;
        citationByYear[year] = (citationByYear[year] ?? 0) + work.citedByCount;
      }

      final journal = _safeName(work.sourceName, 'Unknown Journal');
      journalCounts[journal] = (journalCounts[journal] ?? 0) + 1;
      journalCitations[journal] =
          (journalCitations[journal] ?? 0) + work.citedByCount;

      // Keyword: gom theo tần suất + trích dẫn + phân bố theo năm.
      for (final kw in work.keywords.map((k) => k.trim()).toSet()) {
        if (kw.isEmpty) continue;
        keywordCounts[kw] = (keywordCounts[kw] ?? 0) + 1;
        keywordCitations[kw] = (keywordCitations[kw] ?? 0) + work.citedByCount;
        if (year != null) {
          (keywordYearCounts[kw] ??= <int, int>{})
              .update(year, (v) => v + 1, ifAbsent: () => 1);
          keywordYearSum[kw] = (keywordYearSum[kw] ?? 0) + year;
          keywordYearOccur[kw] = (keywordYearOccur[kw] ?? 0) + 1;
        }
      }

      // Tổ chức: gom các institution duy nhất xuất hiện trong bài.
      final institutionsInWork = <String>{
        for (final a in work.authors) ...a.institutions,
      }..removeWhere((s) => s.trim().isEmpty);
      for (final inst in institutionsInWork) {
        institutionCounts[inst] = (institutionCounts[inst] ?? 0) + 1;
        institutionCitations[inst] =
            (institutionCitations[inst] ?? 0) + work.citedByCount;
      }

      if (work.authors.isEmpty) {
        authorCounts['Unknown Author'] =
            (authorCounts['Unknown Author'] ?? 0) + 1;
        authorCitations['Unknown Author'] =
            (authorCitations['Unknown Author'] ?? 0) + work.citedByCount;
      } else {
        final authorsInWork = work.authors
            .map((author) => _safeName(author.displayName, 'Unknown Author'))
            .toSet();
        for (final author in authorsInWork) {
          authorCounts[author] = (authorCounts[author] ?? 0) + 1;
          authorCitations[author] =
              (authorCitations[author] ?? 0) + work.citedByCount;
        }
      }
    }

    final yearlyTrend =
        yearCounts.entries
            .map((entry) => TrendPoint(year: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    final citationTrend =
        citationByYear.entries
            .map((entry) => TrendPoint(year: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    // #9: mỗi tác giả → (số bài, tổng trích dẫn), lấy ~40 cho scatter.
    final authorStats = _impactStats(authorCounts, authorCitations).take(40);

    // #11: mỗi tổ chức → (số bài, tổng trích dẫn).
    final institutionStats =
        _impactStats(institutionCounts, institutionCitations).take(40);

    // Journal Impact: mỗi journal → (số bài, tổng trích dẫn).
    final journalStats =
        _impactStats(journalCounts, journalCitations).take(40);

    final mostActiveYear = yearlyTrend.isEmpty
        ? null
        : yearlyTrend.reduce((current, candidate) {
            if (candidate.count > current.count) return candidate;
            if (candidate.count == current.count &&
                candidate.year > current.year) {
              return candidate;
            }
            return current;
          }).year;

    final topPapers = [...works]
      ..sort((a, b) {
        final citationOrder = b.citedByCount.compareTo(a.citedByCount);
        if (citationOrder != 0) return citationOrder;
        return (b.publicationYear ?? 0).compareTo(a.publicationYear ?? 0);
      });

    // Bài báo có năm xuất bản → dữ liệu cho scatter Năm × Citations.
    final scatterPapers =
        works.where((w) => w.publicationYear != null).toList(growable: false);

    // #4 + #27: dữ liệu keyword theo thời gian.
    final emergingKeywords = _emergingKeywords(keywordCounts, keywordYearCounts);
    final frontierKeywords = _frontierKeywords(
      keywordCounts,
      keywordCitations,
      keywordYearSum,
      keywordYearOccur,
    );

    return ResearchDashboardSummary(
      topic: topic,
      totalPublications: worksPage.total,
      totalCitations: totalCitations,
      averageCitations: works.isEmpty ? 0 : totalCitations / works.length,
      mostActiveYear: mostActiveYear,
      sampleSize: works.length,
      yearlyTrend: yearlyTrend,
      citationTrend: citationTrend,
      topJournals: _rank(journalCounts, limit: 5),
      topAuthors: _rank(authorCounts, limit: 5),
      topKeywords: _rank(keywordCounts, limit: 8),
      topInstitutions: _rank(institutionCounts, limit: 5),
      authorStats: authorStats.toList(growable: false),
      institutionStats: institutionStats.toList(growable: false),
      journalStats: journalStats.toList(growable: false),
      emergingKeywords: emergingKeywords,
      frontierKeywords: frontierKeywords,
      topPapers: topPapers.take(5).toList(growable: false),
      scatterPapers: scatterPapers,
    );
  }

  /// Chuyển (counts, citations) → danh sách ImpactStat sắp giảm theo số bài.
  List<ImpactStat> _impactStats(
    Map<String, int> counts,
    Map<String, int> citations,
  ) {
    return counts.entries
        .map((e) => ImpactStat(
              name: e.key,
              papers: e.value,
              citations: citations[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) {
        final byPapers = b.papers.compareTo(a.papers);
        return byPapers != 0 ? byPapers : b.citations.compareTo(a.citations);
      });
  }

  /// #4 Emerging Keywords: chọn ~5 keyword có nhiều bài ở các năm gần nhất,
  /// trả về chuỗi số bài theo năm (điền 0 cho năm trống để các đường thẳng hàng).
  List<KeywordSeries> _emergingKeywords(
    Map<String, int> keywordCounts,
    Map<String, Map<int, int>> keywordYearCounts,
  ) {
    final allYears = <int>{
      for (final m in keywordYearCounts.values) ...m.keys,
    };
    if (allYears.length < 2) return const [];

    final maxYear = allYears.reduce((a, b) => a > b ? a : b);
    final minYear = allYears.reduce((a, b) => a < b ? a : b);
    // Giới hạn ~8 năm gần nhất cho dễ đọc.
    final rangeStart = (maxYear - 7) > minYear ? (maxYear - 7) : minYear;

    int recentScore(String kw) {
      final m = keywordYearCounts[kw] ?? const {};
      var s = 0;
      for (var y = maxYear - 2; y <= maxYear; y++) {
        s += m[y] ?? 0;
      }
      return s;
    }

    final candidates = keywordCounts.entries
        .where((e) => e.value >= 2 && (keywordYearCounts[e.key]?.length ?? 0) >= 2)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) {
        final byRecent = recentScore(b).compareTo(recentScore(a));
        return byRecent != 0
            ? byRecent
            : (keywordCounts[b] ?? 0).compareTo(keywordCounts[a] ?? 0);
      });

    return candidates.take(5).map((kw) {
      final m = keywordYearCounts[kw] ?? const {};
      final points = [
        for (var y = rangeStart; y <= maxYear; y++)
          TrendPoint(year: y, count: m[y] ?? 0),
      ];
      return KeywordSeries(keyword: kw, points: points);
    }).toList(growable: false);
  }

  /// #27 Research Frontier: mỗi keyword → (năm TB, số bài, trích dẫn).
  /// Năm TB càng mới + số bài càng nhiều = càng "frontier".
  List<KeywordFrontierPoint> _frontierKeywords(
    Map<String, int> keywordCounts,
    Map<String, int> keywordCitations,
    Map<String, int> keywordYearSum,
    Map<String, int> keywordYearOccur,
  ) {
    final points = <KeywordFrontierPoint>[];
    for (final entry in keywordCounts.entries) {
      final kw = entry.key;
      final occur = keywordYearOccur[kw] ?? 0;
      if (entry.value < 2 || occur == 0) continue;
      points.add(KeywordFrontierPoint(
        keyword: kw,
        meanYear: (keywordYearSum[kw] ?? 0) / occur,
        papers: entry.value,
        citations: keywordCitations[kw] ?? 0,
      ));
    }
    points.sort((a, b) => b.papers.compareTo(a.papers));
    return points.take(25).toList(growable: false);
  }

  List<RankedResearchItem> _rank(
    Map<String, int> counts, {
    required int limit,
  }) {
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countOrder = b.value.compareTo(a.value);
        return countOrder != 0 ? countOrder : a.key.compareTo(b.key);
      });

    return entries
        .take(limit)
        .map((entry) => RankedResearchItem(name: entry.key, count: entry.value))
        .toList(growable: false);
  }

  String _safeName(String? value, String fallback) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? fallback : normalized;
  }
}
