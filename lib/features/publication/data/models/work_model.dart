import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/abstract_decoder.dart';
import '../../domain/entities/work.dart';
import 'author_model.dart';

class WorkModel extends Work {
  const WorkModel({
    required super.id,
    super.doi,
    required super.title,
    super.publicationYear,
    super.publicationDate,
    super.type,
    required super.citedByCount,
    required super.authors,
    super.sourceName,
    super.abstract_,
    required super.isOpenAccess,
    super.landingPageUrl,
    super.oaUrl,
    super.oaStatus,
    super.license,
    super.issn,
    super.volume,
    super.issue,
    super.firstPage,
    super.lastPage,
    super.primaryTopicName,
    super.keywords = const [],
  });

  factory WorkModel.fromJson(Map<String, dynamic> json) {
    try {
      final authorships = json['authorships'] as List<dynamic>? ?? [];
      final authors = authorships
          .whereType<Map<String, dynamic>>()
          .map(AuthorModel.fromJson)
          .toList();

      final primaryLocation =
          json['primary_location'] as Map<String, dynamic>?;
      final bestOaLocation = json['best_oa_location'] as Map<String, dynamic>?;
      final source = primaryLocation?['source'] as Map<String, dynamic>?;
      final openAccess = json['open_access'] as Map<String, dynamic>?;
      final biblio = json['biblio'] as Map<String, dynamic>?;
      final primaryTopic = json['primary_topic'] as Map<String, dynamic>?;
      final abstractIndex =
          json['abstract_inverted_index'] as Map<String, dynamic>?;

      return WorkModel(
        id: json['id'] as String? ?? '',
        doi: json['doi'] as String?,
        title: (json['title'] as String?) ??
            (json['display_name'] as String?) ??
            'Untitled',
        publicationYear: json['publication_year'] as int?,
        publicationDate: json['publication_date'] as String?,
        type: json['type'] as String?,
        citedByCount: json['cited_by_count'] as int? ?? 0,
        authors: authors,
        sourceName: source?['display_name'] as String?,
        abstract_: AbstractDecoder.reconstruct(abstractIndex),
        isOpenAccess: openAccess?['is_oa'] as bool? ?? false,
        landingPageUrl: _readUrl(bestOaLocation?['landing_page_url']) ??
            _readUrl(primaryLocation?['landing_page_url']),
        oaUrl: _readUrl(openAccess?['oa_url']),
        oaStatus: openAccess?['oa_status'] as String?,
        license: _readString(bestOaLocation?['license']) ??
            _readString(primaryLocation?['license']),
        issn: source?['issn_l'] as String?,
        volume: _stringify(biblio?['volume']),
        issue: _stringify(biblio?['issue']),
        firstPage: _stringify(biblio?['first_page']),
        lastPage: _stringify(biblio?['last_page']),
        primaryTopicName: primaryTopic?['display_name'] as String?,
        keywords: _parseKeywords(json['keywords']),
      );
    } catch (e) {
      throw ParsingException('Failed to parse work: $e');
    }
  }

  static String? _readUrl(dynamic value) {
    final url = _readString(value);
    if (url == null) return null;
    return url.startsWith('http') ? url : null;
  }

  static String? _readString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _stringify(dynamic value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _parseKeywords(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((k) => k['display_name'] as String?)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .take(8)
        .toList(growable: false);
  }
}
