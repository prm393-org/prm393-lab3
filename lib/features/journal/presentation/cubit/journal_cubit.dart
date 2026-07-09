import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/entities/trend_point.dart';
import '../../../publication/domain/entities/work.dart';
import '../../../publication/domain/usecases/get_topic_trend.dart';
import '../../../publication/domain/usecases/get_works_by_topic.dart';
import 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  final GetWorksByTopic _getWorksByTopic;
  final GetTopicTrend _getTopicTrend;

  JournalCubit(this._getWorksByTopic, this._getTopicTrend)
      : super(const JournalInitial());

  static const _perPage = 25;

  Topic? _topic;
  int _page = 1;
  int? _year;
  WorkSortOption _sort = WorkSortOption.citations;

  Future<void> loadByTopic(Topic topic) async {
    final isNewTopic = _topic?.id != topic.id;
    _topic = topic;
    // Đổi chủ đề thì reset bộ lọc (các năm khả dụng thay đổi theo chủ đề).
    if (isNewTopic) {
      _year = null;
      _sort = WorkSortOption.citations;
    }
    _page = 1;
    emit(JournalLoading(topic));

    // Works (trang 1) + trend (4.3) chạy song song; trend lỗi không chặn list.
    final worksFuture = _getWorksByTopic(
      GetWorksByTopicParams(
        topicId: topic.shortId,
        page: 1,
        perPage: _perPage,
        year: _year,
        sort: _sort.value,
      ),
    );
    final trendFuture =
        _getTopicTrend(GetTopicTrendParams(topicId: topic.shortId));

    final worksResult = await worksFuture;
    final trendResult = await trendFuture;

    worksResult.fold(
      (failure) => emit(JournalError(failure.message, topic)),
      (paged) {
        final trend = trendResult.getOrElse(() => const <TrendPoint>[]);
        emit(JournalLoaded(
          works: paged.items,
          trend: trend,
          topic: topic,
          total: paged.total,
          hasMore: paged.hasMore,
          year: _year,
          sort: _sort,
        ));
      },
    );
  }

  /// Lọc theo năm xuất bản (null = bỏ lọc). Giữ nguyên trend, tải lại từ trang 1.
  Future<void> setYear(int? year) async {
    if (_year == year) return;
    _year = year;
    await _reloadWorks();
  }

  /// Đổi cách sắp xếp. Giữ nguyên trend, tải lại từ trang 1.
  Future<void> setSort(WorkSortOption sort) async {
    if (_sort == sort) return;
    _sort = sort;
    await _reloadWorks();
  }

  /// Tải lại trang 1 với bộ lọc/sắp xếp hiện tại, giữ lại biểu đồ trend.
  Future<void> _reloadWorks() async {
    final s = state;
    final topic = _topic;
    if (s is! JournalLoaded || topic == null) return;
    _page = 1;
    emit(s.copyWith(
      works: const [],
      isLoadingMore: true,
      year: _year,
      clearYear: _year == null,
      sort: _sort,
    ));

    final result = await _getWorksByTopic(
      GetWorksByTopicParams(
        topicId: topic.shortId,
        page: 1,
        perPage: _perPage,
        year: _year,
        sort: _sort.value,
      ),
    );

    result.fold(
      (failure) => emit(JournalError(failure.message, topic)),
      (paged) => emit(s.copyWith(
        works: paged.items,
        total: paged.total,
        hasMore: paged.hasMore,
        isLoadingMore: false,
        year: _year,
        clearYear: _year == null,
        sort: _sort,
      )),
    );
  }

  Future<void> loadMore() async {
    final s = state;
    final topic = _topic;
    if (s is! JournalLoaded || topic == null || !s.hasMore || s.isLoadingMore) {
      return;
    }
    emit(s.copyWith(isLoadingMore: true));
    _page++;

    final result = await _getWorksByTopic(
      GetWorksByTopicParams(
        topicId: topic.shortId,
        page: _page,
        perPage: _perPage,
        year: _year,
        sort: _sort.value,
      ),
    );

    result.fold(
      (_) => emit(s.copyWith(isLoadingMore: false)),
      (paged) => emit(s.copyWith(
        works: <Work>[...s.works, ...paged.items],
        total: paged.total,
        hasMore: paged.hasMore,
        isLoadingMore: false,
      )),
    );
  }

  void clear() {
    _topic = null;
    _page = 1;
    _year = null;
    _sort = WorkSortOption.citations;
    emit(const JournalInitial());
  }
}
