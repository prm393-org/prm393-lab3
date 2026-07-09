import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/publication/domain/entities/work.dart';

void openWorkDetail(BuildContext context, Work work) {
  context.push('/journal/detail/${work.shortId}', extra: work);
}
