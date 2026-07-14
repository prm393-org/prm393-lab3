import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/paged.dart';
import '../entities/topic.dart';
import '../repositories/publication_repository.dart';

/// Bộ lọc/sắp xếp topic trên tab Home.
enum TopicSortFilter {
  popular, // Phổ biến — works_count
  influence, // Ảnh hưởng — cited_by_count
  quality, // Chất lượng — trung bình trích dẫn (sort client-side)
  byField, // Theo lĩnh vực — nhóm theo domain/field
}

extension TopicSortFilterX on TopicSortFilter {
  String get label => switch (this) {
        TopicSortFilter.popular => 'Popular',
        TopicSortFilter.influence => 'Influence',
        TopicSortFilter.quality => 'Quality',
        TopicSortFilter.byField => 'By field',
      };

  /// Tham số `sort` gửi lên OpenAlex.
  String get apiSort => switch (this) {
        TopicSortFilter.influence => 'cited_by_count:desc',
        _ => 'works_count:desc',
      };
}

class SearchTopics implements UseCase<Paged<Topic>, SearchTopicsParams> {
  final PublicationRepository _repository;
  SearchTopics(this._repository);

  @override
  Future<Either<Failure, Paged<Topic>>> call(SearchTopicsParams params) {
    final hasQuery = params.query != null && params.query!.trim().isNotEmpty;
    // Có query → relevance (OpenAlex). Sort works_count lúc search sẽ trả
    // topic "phổ biến" lệch nghĩa (vd. geochemistry) → ít/không có keywords.
    final sort = hasQuery ? 'relevance_score:desc' : params.filter.apiSort;
    return _repository.searchTopics(
      query: params.query,
      sort: sort,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

class SearchTopicsParams extends Equatable {
  final String? query;
  final TopicSortFilter filter;
  final int page;
  final int perPage;

  const SearchTopicsParams({
    this.query,
    this.filter = TopicSortFilter.popular,
    this.page = 1,
    this.perPage = 25,
  });

  @override
  List<Object?> get props => [query, filter, page, perPage];
}
