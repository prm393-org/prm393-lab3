import 'package:equatable/equatable.dart';

class JournalSummary extends Equatable {
  final String id;
  final String displayName;
  final String? issn;
  final String? publisher;
  final int publicationCount;
  final int citationCount;
  final bool isCitationEstimate;

  const JournalSummary({
    required this.id,
    required this.displayName,
    required this.publicationCount,
    required this.citationCount,
    this.issn,
    this.publisher,
    this.isCitationEstimate = false,
  });

  double get averageCitations =>
      publicationCount == 0 ? 0 : citationCount / publicationCount;

  String get shortId => id.split('/').last;

  bool get hasValidId => shortId.startsWith('S') && shortId.length > 1;

  JournalSummary copyWith({
    String? displayName,
    String? issn,
    String? publisher,
    int? publicationCount,
    int? citationCount,
    bool? isCitationEstimate,
  }) {
    return JournalSummary(
      id: id,
      displayName: displayName ?? this.displayName,
      issn: issn ?? this.issn,
      publisher: publisher ?? this.publisher,
      publicationCount: publicationCount ?? this.publicationCount,
      citationCount: citationCount ?? this.citationCount,
      isCitationEstimate: isCitationEstimate ?? this.isCitationEstimate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    issn,
    publisher,
    publicationCount,
    citationCount,
    isCitationEstimate,
  ];
}
