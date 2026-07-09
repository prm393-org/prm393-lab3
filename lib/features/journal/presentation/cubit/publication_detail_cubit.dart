import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../publication/domain/entities/work.dart';
import '../../../publication/domain/usecases/get_work_by_id.dart';
import 'publication_detail_state.dart';

class PublicationDetailCubit extends Cubit<PublicationDetailState> {
  final GetWorkById _getWorkById;

  PublicationDetailCubit(this._getWorkById)
      : super(const PublicationDetailInitial());

  String? _workId;
  Work? _preview;

  Future<void> load({required String workId, Work? preview}) async {
    _workId = _normalizeWorkId(workId);
    _preview = preview;
    emit(PublicationDetailLoading(preview: preview));
    await _fetch();
  }

  Future<void> retry() async {
    if (_workId == null) return;
    emit(PublicationDetailLoading(preview: _preview));
    await _fetch();
  }

  Future<void> _fetch() async {
    final workId = _workId;
    if (workId == null) return;

    final result = await _getWorkById(GetWorkByIdParams(workId: workId));
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        PublicationDetailError(message: failure.message, preview: _preview),
      ),
      (work) => emit(PublicationDetailLoaded(work)),
    );
  }

  String _normalizeWorkId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('W')) return 'https://openalex.org/$trimmed';
    return trimmed;
  }
}
