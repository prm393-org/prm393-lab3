import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../publication/domain/entities/topic.dart';

/// State dùng chung bắc cầu Home → Journal: topic đang được chọn.
class SelectedTopicViewModel extends Notifier<Topic?> {
  @override
  Topic? build() => null;

  void select(Topic topic) => state = topic;

  void clear() => state = null;
}

final selectedTopicProvider =
    NotifierProvider<SelectedTopicViewModel, Topic?>(SelectedTopicViewModel.new);
