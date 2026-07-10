import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/usecases/search_topics.dart';
import '../../../publication/providers/publication_providers.dart';
import 'home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  static const _perPage = 25;

  TopicSortFilter _filter = TopicSortFilter.popular;
  String? _query;
  int _page = 1;

  @override
  HomeState build() => const HomeInitial();

  SearchTopics get _searchTopics => ref.read(searchTopicsProvider);

  Future<void> initialize() async {
    if (state is! HomeInitial) return;
    final raw = ref
        .read(sharedPreferencesProvider)
        .getString(AppConstants.prefDefaultHomeFilter);
    if (raw != null) {
      _filter = TopicSortFilter.values.asNameMap()[raw] ?? TopicSortFilter.popular;
    }
    await _load(reset: true);
  }

  Future<void> search(String query) {
    _query = query.trim().isEmpty ? null : query.trim();
    if (_query != null) {
      ref.read(recentSearchesStoreProvider).add(_query!);
    }
    return _load(reset: true);
  }

  Future<void> changeFilter(TopicSortFilter filter) {
    _filter = filter;
    return _load(reset: true);
  }

  Future<void> retry() => _load(reset: true);

  /// Tải trang đầu (reset) hoặc trang kế tiếp (loadMore).
  Future<void> _load({required bool reset}) async {
    if (reset) {
      _page = 1;
      state = HomeLoading(filter: _filter, query: _query);
    }

    final result = await _searchTopics(SearchTopicsParams(
      query: _query,
      filter: _filter,
      page: _page,
      perPage: _perPage,
    ));
    if (!ref.mounted) return;

    result.fold(
      (failure) {
        // Lỗi khi loadMore: giữ danh sách hiện có, chỉ tắt cờ loading.
        final s = state;
        if (!reset && s is HomeLoaded) {
          state = s.copyWith(isLoadingMore: false);
        } else {
          state = HomeError(failure.message, filter: _filter, query: _query);
        }
      },
      (paged) {
        final s = state;
        final existing =
            (!reset && s is HomeLoaded) ? s.topics : <Topic>[];
        final merged = _sorted([...existing, ...paged.items]);
        state = HomeLoaded(
          topics: merged,
          total: paged.total,
          hasMore: paged.hasMore,
          isLoadingMore: false,
          filter: _filter,
          query: _query,
        );
      },
    );
  }

  Future<void> loadMore() async {
    final s = state;
    if (s is! HomeLoaded || !s.hasMore || s.isLoadingMore) return;
    state = s.copyWith(isLoadingMore: true);
    _page++;
    await _load(reset: false);
  }

  /// "Chất lượng" sắp xếp theo trung bình trích dẫn trên toàn bộ list đã tải.
  List<Topic> _sorted(List<Topic> topics) {
    if (_filter != TopicSortFilter.quality) return topics;
    return [...topics]..sort((a, b) => b.avgCitations.compareTo(a.avgCitations));
  }
}

final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
