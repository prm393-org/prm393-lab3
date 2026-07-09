import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../publication/domain/entities/topic.dart';

/// State dùng chung bắc cầu Home → Journal: topic đang được chọn.
class SelectedTopicCubit extends Cubit<Topic?> {
  SelectedTopicCubit() : super(null);

  void select(Topic topic) => emit(topic);
  void clear() => emit(null);
}
