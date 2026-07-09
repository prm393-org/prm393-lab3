import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// Wrapper mỏng quanh [Dio] cấu hình sẵn base URL + timeout cho OpenAlex.
///
/// `api_key` và `mailto` (polite pool) được gắn động qua interceptor để
/// tránh hard-code key trong source.
class ApiClient {
  final Dio dio;

  ApiClient(this.dio) {
    dio.options
      ..baseUrl = AppConstants.openAlexBaseUrl
      ..connectTimeout = AppConstants.connectTimeout
      ..receiveTimeout = AppConstants.receiveTimeout
      ..responseType = ResponseType.json;
  }

  /// Cập nhật query params mặc định (gọi sau khi user lưu key/email).
  void setCredentials({String? apiKey, String? mailto}) {
    final params = Map<String, dynamic>.from(dio.options.queryParameters);
    if (apiKey != null && apiKey.isNotEmpty) {
      params['api_key'] = apiKey;
    } else {
      params.remove('api_key');
    }
    if (mailto != null && mailto.isNotEmpty) {
      params['mailto'] = mailto;
    } else {
      params.remove('mailto');
    }
    dio.options.queryParameters = params;
  }
}
