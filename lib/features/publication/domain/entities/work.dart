import 'package:equatable/equatable.dart';

import 'author.dart';

class Work extends Equatable {
  final String id;
  final String? doi;
  final String title;
  final int? publicationYear;
  final String? publicationDate;
  final String? type;
  final int citedByCount;
  final List<Author> authors;
  final String? sourceName;
  final String? abstract_;
  final bool isOpenAccess;
  final String? landingPageUrl;
  final String? oaUrl;
  final String? oaStatus;
  final String? license;
  final String? issn;
  final String? volume;
  final String? issue;
  final String? firstPage;
  final String? lastPage;
  final String? primaryTopicName;
  final List<String> keywords;

  const Work({
    required this.id,
    this.doi,
    required this.title,
    this.publicationYear,
    this.publicationDate,
    this.type,
    required this.citedByCount,
    required this.authors,
    this.sourceName,
    this.abstract_,
    required this.isOpenAccess,
    this.landingPageUrl,
    this.oaUrl,
    this.oaStatus,
    this.license,
    this.issn,
    this.volume,
    this.issue,
    this.firstPage,
    this.lastPage,
    this.primaryTopicName,
    this.keywords = const [],
  });

  String get shortId => id.split('/').last;

  String? get biblioLabel {
    final parts = <String>[];
    if (volume != null && volume!.isNotEmpty) parts.add('Vol. $volume');
    if (issue != null && issue!.isNotEmpty) parts.add('No. $issue');
    if (firstPage != null && firstPage!.isNotEmpty) {
      final pages = lastPage != null &&
              lastPage!.isNotEmpty &&
              lastPage != firstPage
          ? '$firstPage–$lastPage'
          : firstPage!;
      parts.add('pp. $pages');
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  List<Object?> get props => [id];
}
