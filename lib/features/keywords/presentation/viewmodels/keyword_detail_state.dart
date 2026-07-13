import 'package:equatable/equatable.dart';

import '../../../publication/domain/entities/keyword.dart';
import '../../domain/entities/keyword_detail_summary.dart';

abstract class KeywordDetailState extends Equatable {
  const KeywordDetailState();

  @override
  List<Object?> get props => [];
}

class KeywordDetailInitial extends KeywordDetailState {
  const KeywordDetailInitial();
}

class KeywordDetailLoading extends KeywordDetailState {
  final Keyword keyword;

  const KeywordDetailLoading(this.keyword);

  @override
  List<Object?> get props => [keyword];
}

class KeywordDetailLoaded extends KeywordDetailState {
  final KeywordDetailSummary summary;

  /// Trend gọi riêng bằng `group_by`; nếu chỉ mình nó lỗi thì vẫn hiển thị
  /// phần còn lại và báo trend đang dựng từ mẫu.
  final String? trendWarning;

  const KeywordDetailLoaded(this.summary, {this.trendWarning});

  @override
  List<Object?> get props => [summary, trendWarning];
}

class KeywordDetailEmpty extends KeywordDetailState {
  final Keyword keyword;

  const KeywordDetailEmpty(this.keyword);

  @override
  List<Object?> get props => [keyword];
}

class KeywordDetailError extends KeywordDetailState {
  final String message;
  final Keyword keyword;

  const KeywordDetailError(this.message, this.keyword);

  @override
  List<Object?> get props => [message, keyword];
}
