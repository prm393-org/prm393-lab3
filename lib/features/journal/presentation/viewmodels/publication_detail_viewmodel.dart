import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../firebase/firebase_providers.dart';
import '../../../publication/domain/entities/work.dart';
import '../../../publication/domain/usecases/get_work_by_id.dart';
import '../../../publication/providers/publication_providers.dart';
import 'publication_detail_state.dart';

class PublicationDetailViewModel extends Notifier<PublicationDetailState> {
  String? _workId;
  Work? _preview;
  bool _analyticsLogged = false;

  @override
  PublicationDetailState build() => const PublicationDetailInitial();

  GetWorkById get _getWorkById => ref.read(getWorkByIdProvider);

  Future<void> load({required String workId, Work? preview}) async {
    final normalized = _normalizeWorkId(workId);
    if (normalized != _workId) _analyticsLogged = false;
    _workId = normalized;
    _preview = preview;
    state = PublicationDetailLoading(preview: preview);

    // Có preview thì log ngay, người dùng đã thấy nội dung bài báo rồi —
    // không cần đợi request chi tiết xong (và cũng không phụ thuộc nó thành công).
    if (preview != null) _logViewPublication(preview);

    await _fetch();
  }

  Future<void> retry() async {
    if (_workId == null) return;
    state = PublicationDetailLoading(preview: _preview);
    await _fetch();
  }

  Future<void> _fetch() async {
    final workId = _workId;
    if (workId == null) return;

    final result = await _getWorkById(GetWorkByIdParams(workId: workId));
    if (!ref.mounted) return;

    result.fold(
      (failure) => state =
          PublicationDetailError(message: failure.message, preview: _preview),
      (work) {
        // Vào bằng deep link (không preview): tới đây mới biết title/year.
        _logViewPublication(work);
        state = PublicationDetailLoaded(work);
      },
    );
  }

  /// Analytics `view_publication` (mục 5). Chỉ log một lần cho mỗi bài báo —
  /// `retry()` hay reload không được tính thành lượt xem mới.
  void _logViewPublication(Work work) {
    if (_analyticsLogged) return;
    _analyticsLogged = true;
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logViewPublication(
            title: work.title,
            year: work.publicationYear,
          )
          .catchError((_) {}),
    );
  }

  String _normalizeWorkId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('W')) return 'https://openalex.org/$trimmed';
    return trimmed;
  }
}

/// `autoDispose` vì mỗi lần mở một publication khác nhau phải bắt đầu lại từ
/// [PublicationDetailInitial], không dùng lại state của bài trước.
final publicationDetailViewModelProvider = NotifierProvider.autoDispose<
    PublicationDetailViewModel, PublicationDetailState>(
  PublicationDetailViewModel.new,
);
