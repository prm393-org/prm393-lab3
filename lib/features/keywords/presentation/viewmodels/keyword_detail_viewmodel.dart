import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../firebase/firebase_providers.dart';
import '../../../publication/domain/entities/keyword.dart';
import '../../../publication/domain/usecases/get_keyword_trend.dart';
import '../../../publication/domain/usecases/get_works_by_keyword.dart';
import '../../../publication/providers/publication_providers.dart';
import '../../domain/usecases/build_keyword_detail.dart';
import 'keyword_detail_state.dart';

class KeywordDetailViewModel extends Notifier<KeywordDetailState> {
  static const int _sampleSize = 100;

  Keyword? _keyword;
  int _requestId = 0;
  bool _analyticsLogged = false;

  @override
  KeywordDetailState build() => const KeywordDetailInitial();

  GetWorksByKeyword get _getWorksByKeyword =>
      ref.read(getWorksByKeywordProvider);
  GetKeywordTrend get _getKeywordTrend => ref.read(getKeywordTrendProvider);
  BuildKeywordDetail get _buildKeywordDetail =>
      ref.read(buildKeywordDetailProvider);

  Future<void> load(Keyword keyword) async {
    if (_keyword != keyword) _analyticsLogged = false;
    _keyword = keyword;
    final requestId = ++_requestId;
    state = KeywordDetailLoading(keyword);
    _logOnce(keyword);

    // Hai request độc lập → chạy song song, đừng nối tiếp.
    final worksFuture = _getWorksByKeyword(
      GetWorksByKeywordParams(
        keywordId: keyword.filterId,
        perPage: _sampleSize,
        sort: 'cited_by_count:desc',
      ),
    );
    final trendFuture = _getKeywordTrend(
      GetKeywordTrendParams(keywordId: keyword.filterId),
    );

    final worksResult = await worksFuture;
    final trendResult = await trendFuture;

    // Bỏ qua kết quả của request đã bị thay thế bởi lần load mới hơn.
    if (requestId != _requestId || !ref.mounted) return;

    // Trend lỗi không đủ để chặn cả màn hình — BuildKeywordDetail sẽ dựng
    // trend từ mẫu, ta chỉ ghi chú lại cho người dùng biết.
    final trend = trendResult.fold((_) => null, (points) => points);

    worksResult.fold(
      (failure) => state = KeywordDetailError(failure.message, keyword),
      (paged) {
        if (paged.items.isEmpty) {
          state = KeywordDetailEmpty(keyword);
          return;
        }
        state = KeywordDetailLoaded(
          _buildKeywordDetail(
            keyword: keyword,
            worksPage: paged,
            trend: trend ?? const [],
            journalLimit: ref
                .read(remoteConfigServiceProvider)
                .maxJournalsDisplayed,
          ),
          trendWarning: trend == null
              ? 'Publication trend is estimated from the sample.'
              : null,
        );
      },
    );
  }

  Future<void> retry() async {
    final keyword = _keyword;
    if (keyword != null) await load(keyword);
  }

  void _logOnce(Keyword keyword) {
    if (_analyticsLogged) return;
    _analyticsLogged = true;
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logViewKeyword(keyword.displayName)
          .catchError((_) {}),
    );
  }
}

final keywordDetailViewModelProvider =
    NotifierProvider.autoDispose<KeywordDetailViewModel, KeywordDetailState>(
      KeywordDetailViewModel.new,
    );
