import 'package:flutter_bloc/flutter_bloc.dart';

/// State dùng chung bắc cầu Profile/nơi khác → ô tìm kiếm ở Home.
///
/// Khi người dùng chọn một mục (vd: từ lịch sử tìm kiếm trong Profile),
/// gọi [request] để yêu cầu Home điền sẵn và tìm từ khoá đó. Ô tìm kiếm
/// lắng nghe state này, xử lý xong thì gọi [clear] để không lặp lại.
class PendingSearchCubit extends Cubit<String?> {
  PendingSearchCubit() : super(null);

  void request(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    emit(q);
  }

  void clear() {
    if (state != null) emit(null);
  }
}
