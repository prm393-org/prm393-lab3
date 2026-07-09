import 'package:equatable/equatable.dart';

import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/usecases/search_topics.dart';

export '../../../publication/domain/usecases/search_topics.dart'
    show TopicSortFilter, TopicSortFilterX;

abstract class HomeState extends Equatable {
  final TopicSortFilter filter;
  final String? query;
  const HomeState({this.filter = TopicSortFilter.popular, this.query});

  @override
  List<Object?> get props => [filter, query];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading({super.filter, super.query});
}

class HomeLoaded extends HomeState {
  final List<Topic> topics;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;

  const HomeLoaded({
    required this.topics,
    required this.total,
    this.hasMore = false,
    this.isLoadingMore = false,
    super.filter,
    super.query,
  });

  HomeLoaded copyWith({
    List<Topic>? topics,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      HomeLoaded(
        topics: topics ?? this.topics,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        filter: filter,
        query: query,
      );

  @override
  List<Object?> get props =>
      [topics, total, hasMore, isLoadingMore, filter, query];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message, {super.filter, super.query});

  @override
  List<Object?> get props => [message, filter, query];
}
