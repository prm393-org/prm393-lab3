import 'package:equatable/equatable.dart';

import '../../../publication/domain/entities/journal_summary.dart';
import '../../../publication/domain/entities/work.dart';

enum RelatedPublicationSort {
  mostCited('Most cited', 'cited_by_count:desc'),
  newest('Newest', 'publication_date:desc'),
  oldest('Oldest', 'publication_date:asc');

  const RelatedPublicationSort(this.label, this.apiValue);
  final String label;
  final String apiValue;
}

sealed class JournalDetailState extends Equatable {
  const JournalDetailState();

  @override
  List<Object?> get props => [];
}

class JournalDetailInitial extends JournalDetailState {
  const JournalDetailInitial();
}

class JournalDetailLoading extends JournalDetailState {
  final JournalSummary? preview;

  const JournalDetailLoading({this.preview});

  @override
  List<Object?> get props => [preview];
}

class JournalDetailLoaded extends JournalDetailState {
  final JournalSummary journal;
  final List<Work> works;
  final int totalWorks;
  final bool hasMore;
  final RelatedPublicationSort sort;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? metadataWarning;
  final String? publicationsError;
  final String? loadMoreError;

  const JournalDetailLoaded({
    required this.journal,
    required this.works,
    required this.totalWorks,
    required this.hasMore,
    this.sort = RelatedPublicationSort.mostCited,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.metadataWarning,
    this.publicationsError,
    this.loadMoreError,
  });

  JournalDetailLoaded copyWith({
    JournalSummary? journal,
    List<Work>? works,
    int? totalWorks,
    bool? hasMore,
    RelatedPublicationSort? sort,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? metadataWarning,
    String? publicationsError,
    String? loadMoreError,
    bool clearMetadataWarning = false,
    bool clearPublicationsError = false,
    bool clearLoadMoreError = false,
  }) {
    return JournalDetailLoaded(
      journal: journal ?? this.journal,
      works: works ?? this.works,
      totalWorks: totalWorks ?? this.totalWorks,
      hasMore: hasMore ?? this.hasMore,
      sort: sort ?? this.sort,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      metadataWarning: clearMetadataWarning
          ? null
          : (metadataWarning ?? this.metadataWarning),
      publicationsError: clearPublicationsError
          ? null
          : (publicationsError ?? this.publicationsError),
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  List<Object?> get props => [
    journal,
    works,
    totalWorks,
    hasMore,
    sort,
    isRefreshing,
    isLoadingMore,
    metadataWarning,
    publicationsError,
    loadMoreError,
  ];
}

class JournalDetailError extends JournalDetailState {
  final String message;
  final JournalSummary? preview;

  const JournalDetailError({required this.message, this.preview});

  @override
  List<Object?> get props => [message, preview];
}
