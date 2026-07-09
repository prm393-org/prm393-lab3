import '../../../../core/error/exceptions.dart';
import '../../domain/entities/topic.dart';

class TopicModel extends Topic {
  const TopicModel({
    required super.id,
    required super.displayName,
    super.description,
    super.keywords,
    super.domainName,
    super.fieldName,
    super.worksCount,
    super.citedByCount,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    try {
      final domain = json['domain'] as Map<String, dynamic>?;
      final field = json['field'] as Map<String, dynamic>?;

      return TopicModel(
        id: json['id'] as String? ?? '',
        displayName: (json['display_name'] as String?) ?? 'Unknown topic',
        description: json['description'] as String?,
        keywords: _parseKeywords(json['keywords']),
        domainName: domain?['display_name'] as String?,
        fieldName: field?['display_name'] as String?,
        worksCount: json['works_count'] as int? ?? 0,
        citedByCount: json['cited_by_count'] as int? ?? 0,
      );
    } catch (e) {
      throw ParsingException('Failed to parse topic: $e');
    }
  }

  /// OpenAlex trả keywords dạng `["a", "b"]` hoặc `[{keyword: "a"}]` tùy phiên bản.
  static List<String> _parseKeywords(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e is String) return e;
          if (e is Map<String, dynamic>) {
            return (e['keyword'] ?? e['display_name'])?.toString();
          }
          return null;
        })
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
