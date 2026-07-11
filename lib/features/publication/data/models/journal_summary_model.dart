import '../../../../core/error/exceptions.dart';
import '../../domain/entities/journal_summary.dart';

class JournalSummaryModel extends JournalSummary {
  const JournalSummaryModel({
    required super.id,
    required super.displayName,
    required super.publicationCount,
    required super.citationCount,
    super.issn,
    super.publisher,
    super.isCitationEstimate,
  });

  factory JournalSummaryModel.fromJson(Map<String, dynamic> json) {
    try {
      final issns = json['issn'] as List<dynamic>?;
      return JournalSummaryModel(
        id: _readString(json['id']) ?? '',
        displayName: _readString(json['display_name']) ?? 'Unknown Source',
        issn:
            _readString(json['issn_l']) ??
            issns?.map(_readString).whereType<String>().firstOrNull,
        publisher: _readString(json['host_organization_name']),
        publicationCount: (json['works_count'] as num?)?.toInt() ?? 0,
        citationCount: (json['cited_by_count'] as num?)?.toInt() ?? 0,
      );
    } catch (error) {
      throw ParsingException('Failed to parse source: $error');
    }
  }

  JournalSummaryModel withTopicMetrics({
    required int publicationCount,
    required int citationCount,
    required bool isCitationEstimate,
    String? fallbackDisplayName,
  }) {
    return JournalSummaryModel(
      id: id,
      displayName:
          displayName == 'Unknown Source' && fallbackDisplayName != null
          ? fallbackDisplayName
          : displayName,
      issn: issn,
      publisher: publisher,
      publicationCount: publicationCount,
      citationCount: citationCount,
      isCitationEstimate: isCitationEstimate,
    );
  }

  static String? _readString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
