import 'package:equatable/equatable.dart';

import '../../../publication/domain/entities/journal_summary.dart';
import '../../../publication/domain/entities/topic.dart';

enum JournalSort {
  publications('Publications'),
  citations('Citations'),
  averageCitations('Avg citations');

  const JournalSort(this.label);
  final String label;
}

sealed class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

class JournalInitial extends JournalState {
  const JournalInitial();
}

class JournalLoading extends JournalState {
  final Topic topic;

  const JournalLoading(this.topic);

  @override
  List<Object?> get props => [topic];
}

class JournalEmpty extends JournalState {
  final Topic topic;

  const JournalEmpty(this.topic);

  @override
  List<Object?> get props => [topic];
}

class JournalLoaded extends JournalState {
  final Topic topic;
  final List<JournalSummary> journals;
  final JournalSort sort;
  final int maxDisplayed;
  final bool isRefreshing;
  final String? refreshError;

  const JournalLoaded({
    required this.topic,
    required this.journals,
    required this.maxDisplayed,
    this.sort = JournalSort.publications,
    this.isRefreshing = false,
    this.refreshError,
  });

  List<JournalSummary> get sortedJournals {
    final result = [...journals]
      ..sort((a, b) {
        final metricComparison = switch (sort) {
          JournalSort.publications => b.publicationCount.compareTo(
            a.publicationCount,
          ),
          JournalSort.citations => b.citationCount.compareTo(a.citationCount),
          JournalSort.averageCitations => b.averageCitations.compareTo(
            a.averageCitations,
          ),
        };
        if (metricComparison != 0) return metricComparison;
        final nameComparison = a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
        return nameComparison != 0 ? nameComparison : a.id.compareTo(b.id);
      });
    return result;
  }

  int get totalPublications =>
      journals.fold(0, (total, journal) => total + journal.publicationCount);

  int get totalCitations =>
      journals.fold(0, (total, journal) => total + journal.citationCount);

  double get averageCitations =>
      totalPublications == 0 ? 0 : totalCitations / totalPublications;

  bool get hasEstimatedCitations =>
      journals.any((journal) => journal.isCitationEstimate);

  JournalLoaded copyWith({
    List<JournalSummary>? journals,
    JournalSort? sort,
    bool? isRefreshing,
    String? refreshError,
    bool clearRefreshError = false,
  }) {
    return JournalLoaded(
      topic: topic,
      journals: journals ?? this.journals,
      maxDisplayed: maxDisplayed,
      sort: sort ?? this.sort,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError: clearRefreshError
          ? null
          : (refreshError ?? this.refreshError),
    );
  }

  @override
  List<Object?> get props => [
    topic,
    journals,
    sort,
    maxDisplayed,
    isRefreshing,
    refreshError,
  ];
}

class JournalError extends JournalState {
  final String message;
  final Topic topic;

  const JournalError(this.message, this.topic);

  @override
  List<Object?> get props => [message, topic];
}
