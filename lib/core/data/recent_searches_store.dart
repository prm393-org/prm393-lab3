import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Nguồn dữ liệu chung cho lịch sử tìm kiếm.
///
/// Là [ChangeNotifier] singleton: Home ghi vào đây, các màn khác (dropdown
/// tìm kiếm, badge ở Profile) lắng nghe để tự cập nhật — không phụ thuộc
/// vòng đời tab (các tab nằm trong IndexedStack nên không rebuild khi switch).
class RecentSearchesStore extends ChangeNotifier {
  RecentSearchesStore(this._prefs);

  final SharedPreferences _prefs;

  /// Số lượng lịch sử tối đa được giữ lại.
  static const int maxItems = 10;

  /// Danh sách hiện tại (mới nhất ở đầu), đọc tươi từ SharedPreferences.
  List<String> get items =>
      _prefs.getStringList(AppConstants.prefRecentSearches) ?? [];

  int get count => items.length;

  /// Thêm một query mới lên đầu; bỏ trùng và giới hạn [maxItems].
  void add(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = items..remove(q);
    list.insert(0, q);
    if (list.length > maxItems) list.removeRange(maxItems, list.length);
    _prefs.setStringList(AppConstants.prefRecentSearches, list);
    notifyListeners();
  }

  /// Xóa toàn bộ lịch sử.
  void clear() {
    _prefs.remove(AppConstants.prefRecentSearches);
    notifyListeners();
  }
}
