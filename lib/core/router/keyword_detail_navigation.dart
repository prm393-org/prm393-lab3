import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/publication/domain/entities/keyword.dart';

/// Mở màn Keyword Detail (FR 4.7). Truyền [Keyword] qua `extra` để hiển thị
/// tên ngay lập tức — slug trên URL không dựng lại được display name.
void openKeywordDetail(BuildContext context, Keyword keyword) {
  context.push('/keywords/detail/${keyword.slug}', extra: keyword);
}
