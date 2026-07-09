import 'package:equatable/equatable.dart';

/// Một chủ đề nghiên cứu từ OpenAlex (`/topics`).
class Topic extends Equatable {
  final String id;
  final String displayName;
  final String? description;
  final List<String> keywords;
  final String? domainName;
  final String? fieldName;
  final int worksCount;
  final int citedByCount;

  const Topic({
    required this.id,
    required this.displayName,
    this.description,
    this.keywords = const [],
    this.domainName,
    this.fieldName,
    this.worksCount = 0,
    this.citedByCount = 0,
  });

  /// Trung bình trích dẫn mỗi bài — dùng cho bộ lọc "Chất lượng".
  double get avgCitations =>
      worksCount == 0 ? 0 : citedByCount / worksCount;

  /// ID rút gọn cho filter OpenAlex, vd "https://openalex.org/T10360" → "T10360".
  String get shortId => id.split('/').last;

  @override
  List<Object?> get props => [id];
}
