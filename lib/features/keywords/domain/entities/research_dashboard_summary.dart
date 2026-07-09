import 'package:equatable/equatable.dart';

import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/entities/trend_point.dart';
import '../../../publication/domain/entities/work.dart';

class RankedResearchItem extends Equatable {
  final String name;
  final int count;

  const RankedResearchItem({required this.name, required this.count});

  @override
  List<Object?> get props => [name, count];
}

/// Thống kê productivity (số bài) vs impact (tổng trích dẫn) cho một thực thể
/// (tác giả hoặc tổ chức) — dùng cho scatter #9 và #11.
class ImpactStat extends Equatable {
  final String name;
  final int papers;
  final int citations;

  const ImpactStat({
    required this.name,
    required this.papers,
    required this.citations,
  });

  @override
  List<Object?> get props => [name, papers, citations];
}

/// Chuỗi số bài theo năm của một keyword — dùng cho #4 Emerging Keywords.
class KeywordSeries extends Equatable {
  final String keyword;
  final List<TrendPoint> points;

  const KeywordSeries({required this.keyword, required this.points});

  @override
  List<Object?> get props => [keyword, points];
}

/// Một keyword trên bản đồ "frontier" (#27): độ mới (năm TB), khối lượng
/// (số bài) và sức ảnh hưởng (tổng trích dẫn).
class KeywordFrontierPoint extends Equatable {
  final String keyword;
  final double meanYear;
  final int papers;
  final int citations;

  const KeywordFrontierPoint({
    required this.keyword,
    required this.meanYear,
    required this.papers,
    required this.citations,
  });

  @override
  List<Object?> get props => [keyword, meanYear, papers, citations];
}

class ResearchDashboardSummary extends Equatable {
  final Topic topic;
  final int totalPublications;
  final int totalCitations;
  final double averageCitations;
  final int? mostActiveYear;
  final int sampleSize;
  final List<TrendPoint> yearlyTrend;

  /// Tổng trích dẫn theo năm (#2 Citation Trend).
  final List<TrendPoint> citationTrend;

  final List<RankedResearchItem> topJournals;
  final List<RankedResearchItem> topAuthors;

  /// Top keyword theo tần suất xuất hiện (#3 Top Keywords).
  final List<RankedResearchItem> topKeywords;

  /// Xếp hạng tổ chức theo số bài trong mẫu (#10 Institution Ranking).
  final List<RankedResearchItem> topInstitutions;

  /// Productivity vs Impact của tác giả (#9, scatter).
  final List<ImpactStat> authorStats;

  /// Productivity vs Impact của tổ chức (#11, bubble).
  final List<ImpactStat> institutionStats;

  /// Productivity vs Impact của journal (bubble).
  final List<ImpactStat> journalStats;

  /// Keyword tăng trưởng nhanh theo năm (#4, multi-line).
  final List<KeywordSeries> emergingKeywords;

  /// Keyword trên bản đồ frontier (#27, bubble).
  final List<KeywordFrontierPoint> frontierKeywords;

  final List<Work> topPapers;

  /// Bài báo (có năm xuất bản) dùng cho scatter Năm × Citations.
  final List<Work> scatterPapers;

  const ResearchDashboardSummary({
    required this.topic,
    required this.totalPublications,
    required this.totalCitations,
    required this.averageCitations,
    required this.mostActiveYear,
    required this.sampleSize,
    required this.yearlyTrend,
    required this.citationTrend,
    required this.topJournals,
    required this.topAuthors,
    required this.topKeywords,
    required this.topInstitutions,
    required this.authorStats,
    required this.institutionStats,
    required this.journalStats,
    required this.emergingKeywords,
    required this.frontierKeywords,
    required this.topPapers,
    required this.scatterPapers,
  });

  RankedResearchItem? get topJournal =>
      topJournals.isEmpty ? null : topJournals.first;

  RankedResearchItem? get topAuthor =>
      topAuthors.isEmpty ? null : topAuthors.first;

  @override
  List<Object?> get props => [
    topic,
    totalPublications,
    totalCitations,
    averageCitations,
    mostActiveYear,
    sampleSize,
    yearlyTrend,
    citationTrend,
    topJournals,
    topAuthors,
    topKeywords,
    topInstitutions,
    authorStats,
    institutionStats,
    journalStats,
    emergingKeywords,
    frontierKeywords,
    topPapers,
    scatterPapers,
  ];
}
