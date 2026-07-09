import 'package:equatable/equatable.dart';

class Author extends Equatable {
  final String? id;
  final String displayName;
  final String? orcid;
  final List<String> affiliations;

  /// Tên tổ chức "sạch" (từ institutions[].display_name) — dùng cho xếp hạng.
  final List<String> institutions;

  const Author({
    this.id,
    required this.displayName,
    this.orcid,
    this.affiliations = const [],
    this.institutions = const [],
  });

  @override
  List<Object?> get props => [id, displayName, orcid, affiliations, institutions];
}
