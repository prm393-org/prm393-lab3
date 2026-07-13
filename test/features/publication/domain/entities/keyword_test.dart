import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/keyword.dart';

void main() {
  test('derives the OpenAlex filter id from the full URL', () {
    const keyword = Keyword(
      id: 'https://openalex.org/keywords/machine-learning',
      displayName: 'Machine learning',
    );

    expect(keyword.slug, 'machine-learning');
    expect(keyword.filterId, 'keywords/machine-learning');
  });

  test('keeps the id slug, which display name cannot reproduce', () {
    // OpenAlex bỏ phần trong ngoặc khi tạo slug — đây chính là lý do Work phải
    // mang theo id thay vì slugify display name.
    const keyword = Keyword(
      id: 'https://openalex.org/keywords/transparency',
      displayName: 'Transparency (behavior)',
    );

    expect(keyword.filterId, 'keywords/transparency');
  });
}
