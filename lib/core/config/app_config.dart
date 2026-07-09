import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cấu hình runtime nạp từ file `.env` (không commit key vào source).
///
/// Ưu tiên đọc từ SharedPreferences (user nhập ở tab Profile) trước,
/// fallback về `.env`. Lớp này chỉ cung cấp giá trị mặc định từ env.
class AppConfig {
  AppConfig._();

  /// API key mặc định (có thể rỗng — user nhập trong Settings).
  static String get defaultApiKey => dotenv.maybeGet('OPENALEX_API_KEY') ?? '';

  /// Email cho "polite pool" của OpenAlex (khuyến nghị theo docs).
  static String get defaultMailto => dotenv.maybeGet('OPENALEX_MAILTO') ?? '';
}
