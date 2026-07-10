import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../publication/domain/entities/work.dart';
import '../../../publication/domain/usecases/get_work_by_id.dart';
import '../../../publication/providers/publication_providers.dart';
import 'publication_detail_state.dart';

class PublicationDetailViewModel extends Notifier<PublicationDetailState> {
  String? _workId;
  Work? _preview;

  @override
  PublicationDetailState build() => const PublicationDetailInitial();

  GetWorkById get _getWorkById => ref.read(getWorkByIdProvider);

  Future<void> load({required String workId, Work? preview}) async {
    _workId = _normalizeWorkId(workId);
    _preview = preview;
    state = PublicationDetailLoading(preview: preview);
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
      (work) => state = PublicationDetailLoaded(work),
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
