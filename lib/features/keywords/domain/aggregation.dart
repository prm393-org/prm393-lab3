import 'entities/research_dashboard_summary.dart';

List<RankedResearchItem> rankByCount(
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

/// (counts, citations) → ImpactStat sắp giảm theo số bài, rồi theo trích dẫn.
List<ImpactStat> impactStats(
  Map<String, int> counts,
  Map<String, int> citations,
) {
  return counts.entries
      .map(
        (e) => ImpactStat(
          name: e.key,
          papers: e.value,
          citations: citations[e.key] ?? 0,
        ),
      )
      .toList()
    ..sort((a, b) {
      final byPapers = b.papers.compareTo(a.papers);
      return byPapers != 0 ? byPapers : b.citations.compareTo(a.citations);
    });
}

String safeName(String? value, String fallback) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? fallback : normalized;
}

/// Năm có nhiều bài nhất; hoà thì lấy năm mới hơn.
int? mostActiveYearOf(Map<int, int> yearCounts) {
  if (yearCounts.isEmpty) return null;
  return yearCounts.entries.reduce((current, candidate) {
    if (candidate.value > current.value) return candidate;
    if (candidate.value == current.value && candidate.key > current.key) {
      return candidate;
    }
    return current;
  }).key;
}
