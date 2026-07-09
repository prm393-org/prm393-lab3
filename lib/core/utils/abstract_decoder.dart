/// Ghép lại abstract từ `abstract_inverted_index` của OpenAlex.
///
/// OpenAlex trả abstract dưới dạng map { từ: [vị trí...] }. Hàm này khôi phục
/// lại đoạn văn theo đúng thứ tự vị trí.
class AbstractDecoder {
  AbstractDecoder._();

  static String? reconstruct(Map<String, dynamic>? invertedIndex) {
    if (invertedIndex == null || invertedIndex.isEmpty) return null;

    final positions = <int, String>{};
    invertedIndex.forEach((word, value) {
      if (value is List) {
        for (final pos in value) {
          if (pos is int) positions[pos] = word;
        }
      }
    });

    if (positions.isEmpty) return null;

    final sortedKeys = positions.keys.toList()..sort();
    return sortedKeys.map((k) => positions[k]).join(' ');
  }
}
