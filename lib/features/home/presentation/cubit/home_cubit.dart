import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/recent_searches_store.dart';
import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/usecases/search_topics.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final SearchTopics _searchTopics;

  HomeCubit(this._searchTopics) : super(const HomeInitial());

  static const _perPage = 25;

  TopicSortFilter _filter = TopicSortFilter.popular;
  String? _query;
  int _page = 1;

  Future<void> initialize() async {
    if (state is! HomeInitial) return;
    if (GetIt.I.isRegistered<SharedPreferences>()) {
      final raw = GetIt.I<SharedPreferences>()
          .getString(AppConstants.prefDefaultHomeFilter);
      if (raw != null) {
        _filter =
            TopicSortFilter.values.asNameMap()[raw] ?? TopicSortFilter.popular;
      }
    }
    await _load(reset: true);
  }

  Future<void> search(String query) {
    _query = query.trim().isEmpty ? null : query.trim();
    if (_query != null && GetIt.I.isRegistered<RecentSearchesStore>()) {
      GetIt.I<RecentSearchesStore>().add(_query!);
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
      emit(HomeLoading(filter: _filter, query: _query));
    }

    final result = await _searchTopics(SearchTopicsParams(
      query: _query,
      filter: _filter,
      page: _page,
      perPage: _perPage,
    ));

    result.fold(
      (failure) {
        // Lỗi khi loadMore: giữ danh sách hiện có, chỉ tắt cờ loading.
        final s = state;
        if (!reset && s is HomeLoaded) {
          emit(s.copyWith(isLoadingMore: false));
        } else {
          emit(HomeError(failure.message, filter: _filter, query: _query));
        }
      },
      (paged) {
        final existing =
            (!reset && state is HomeLoaded) ? (state as HomeLoaded).topics : <Topic>[];
        final merged = _sorted([...existing, ...paged.items]);
        emit(HomeLoaded(
          topics: merged,
          total: paged.total,
          hasMore: paged.hasMore,
          isLoadingMore: false,
          filter: _filter,
          query: _query,
        ));
      },
    );
  }

  Future<void> loadMore() async {
    final s = state;
    if (s is! HomeLoaded || !s.hasMore || s.isLoadingMore) return;
    emit(s.copyWith(isLoadingMore: true));
    _page++;
    await _load(reset: false);
  }

  /// "Chất lượng" sắp xếp theo trung bình trích dẫn trên toàn bộ list đã tải.
  List<Topic> _sorted(List<Topic> topics) {
    if (_filter != TopicSortFilter.quality) return topics;
    return [...topics]
      ..sort((a, b) => b.avgCitations.compareTo(a.avgCitations));
  }
}
