import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/publication/domain/entities/work.dart';

void openWorkDetail(BuildContext context, Work work) {
  context.push('/journal/detail/${work.shortId}', extra: work);
}

/// Mở Publication Detail từ tab Home. Route riêng theo nhánh Home để màn chi
/// tiết chồng lên đúng tab đang đứng, không nhảy người dùng sang tab Journals.
void openWorkDetailFromHome(BuildContext context, Work work) {
  context.push('/home/detail/${work.shortId}', extra: work);
}
