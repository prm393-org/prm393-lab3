import 'package:equatable/equatable.dart';

import '../../../publication/domain/entities/keyword.dart';
import '../../../publication/domain/entities/trend_point.dart';
import '../../../publication/domain/entities/work.dart';
import 'research_dashboard_summary.dart';

/// Dữ liệu màn Keyword Detail (FR 4.7).
///
/// [totalPublications] lấy từ `meta.count` của OpenAlex nên là tổng thật;
/// các số liệu còn lại tính trên mẫu [sampleSize] bài trích dẫn cao nhất.
class KeywordDetailSummary extends Equatable {
  final Keyword keyword;
  final int totalPublications;
  final int totalCitations;
  final double averageCitations;
  final int sampleSize;
  final int? mostActiveYear;

  /// Trend theo năm lấy từ `group_by=publication_year` — toàn bộ keyword,
  /// không chỉ mẫu.
  final List<TrendPoint> yearlyTrend;

  final List<RankedResearchItem> topJournals;
  final List<RankedResearchItem> topAuthors;

  /// Productivity vs impact của tác giả — dữ liệu cho ranking chart.
  final List<ImpactStat> authorStats;

  /// Bài báo tiêu biểu (trích dẫn cao nhất).
  final List<Work> publications;

  const KeywordDetailSummary({
    required this.keyword,
    required this.totalPublications,
    required this.totalCitations,
    required this.averageCitations,
    required this.sampleSize,
    required this.mostActiveYear,
    required this.yearlyTrend,
    required this.topJournals,
    required this.topAuthors,
    required this.authorStats,
    required this.publications,
  });

  @override
  List<Object?> get props => [
    keyword,
    totalPublications,
    totalCitations,
    averageCitations,
    sampleSize,
    mostActiveYear,
    yearlyTrend,
    topJournals,
    topAuthors,
    authorStats,
    publications,
  ];
}
