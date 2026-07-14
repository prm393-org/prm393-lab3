import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/keyword.dart';
import '../../domain/entities/trend_point.dart';
import '../models/journal_summary_model.dart';
import '../models/topic_model.dart';
import '../models/work_model.dart';

/// Kết quả một trang: danh sách + tổng số bản ghi (`meta.count`).
typedef PageResult<T> = ({List<T> items, int total});

abstract class PublicationRemoteDatasource {
  Future<PageResult<TopicModel>> searchTopics({
    String? query,
    String sort = 'works_count:desc',
    int page = 1,
    int perPage = 25,
  });

  Future<PageResult<WorkModel>> getWorksByTopic(
    String topicId, {
    int page = 1,
    int perPage = 25,
    int? year,
    String sort = 'cited_by_count:desc',
  });

  /// Số bài báo theo năm của một topic (OpenAlex `group_by`) — phục vụ 4.3.
  Future<List<TrendPoint>> getTopicTrend(String topicId);

  /// Bài báo gắn một keyword (`/works?filter=keywords.id:...`) — phục vụ 4.7.
  Future<PageResult<WorkModel>> getWorksByKeyword(
    String keywordId, {
    int page = 1,
    int perPage = 25,
    String sort = 'cited_by_count:desc',
  });

  /// Số bài báo theo năm của một keyword — trend đầy đủ, không chỉ trong mẫu.
  Future<List<TrendPoint>> getKeywordTrend(String keywordId);

  /// Chi tiết một bài báo (`/works/{id}`) — phục vụ màn Publication Detail.
  Future<WorkModel> getWorkById(String workId);

  Future<List<JournalSummaryModel>> getJournalsByTopic({
    required String topicId,
    int limit = 10,
  });

  /// Top keywords của topic qua `group_by=keywords.id` (1 request).
  Future<List<({Keyword keyword, int count})>> getKeywordsByTopic({
    required String topicId,
    int limit = 8,
  });

  Future<JournalSummaryModel> getJournalById(String journalId);

  Future<PageResult<WorkModel>> getWorksByJournal({
    required String journalId,
    String? topicId,
    int page = 1,
    int perPage = 20,
    String sort = 'cited_by_count:desc',
  });
}

class PublicationRemoteDatasourceImpl implements PublicationRemoteDatasource {
  final ApiClient _apiClient;
  PublicationRemoteDatasourceImpl(this._apiClient);

  @override
  Future<PageResult<TopicModel>> searchTopics({
    String? query,
    String sort = 'works_count:desc',
    int page = 1,
    int perPage = 25,
  }) async {
    final params = <String, dynamic>{
      'sort': sort,
      'page': page,
      'per_page': perPage,
    };
    if (query != null && query.trim().isNotEmpty) {
      params['search'] = query.trim();
    }
    return _request('/topics', params, TopicModel.fromJson);
  }

  @override
  Future<PageResult<WorkModel>> getWorksByTopic(
    String topicId, {
    int page = 1,
    int perPage = 25,
    int? year,
    String sort = 'cited_by_count:desc',
  }) {
    final filters = <String>['primary_topic.id:${_shortId(topicId)}'];
    if (year != null) filters.add('publication_year:$year');
    return _request('/works', {
      'filter': filters.join(','),
      'sort': sort,
      'page': page,
      'per_page': perPage,
    }, WorkModel.fromJson);
  }

  @override
  Future<WorkModel> getWorkById(String workId) async {
    try {
      final response = await _apiClient.dio.get('/works/${_shortId(workId)}');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ParsingException('Invalid work response');
      }
      return WorkModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on ParsingException {
      rethrow;
    } catch (e) {
      throw ParsingException('Unexpected error: $e');
    }
  }

  @override
  Future<List<JournalSummaryModel>> getJournalsByTopic({
    required String topicId,
    int limit = 10,
  }) async {
    final safeLimit = limit.clamp(1, 200);
    try {
      // Chỉ 1 request `group_by`. Trước đây Future.wait gọi
      // getJournalById + citation sample cho mọi journal song song
      // → OpenAlex 429 Too Many Requests (TC4 fail).
      // Metadata đầy đủ / citation theo topic lấy ở Journal Detail.
      final response = await _apiClient.dio.get(
        '/works',
        queryParameters: {
          'filter': 'primary_topic.id:${_shortId(topicId)}',
          'group_by': 'primary_location.source.id',
          'per_page': safeLimit,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final groups = data?['group_by'] as List<dynamic>? ?? const [];
      return groups
          .whereType<Map<String, dynamic>>()
          .where((group) => _shortId('${group['key']}').startsWith('S'))
          .take(safeLimit)
          .map(_journalFromGroupBy)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ParsingException {
      rethrow;
    } catch (error) {
      throw ParsingException('Unexpected error: $error');
    }
  }

  JournalSummaryModel _journalFromGroupBy(Map<String, dynamic> group) {
    final sourceId = '${group['key']}';
    final short = _shortId(sourceId);
    return JournalSummaryModel(
      id: sourceId.contains('/') ? sourceId : 'https://openalex.org/$short',
      displayName: _readString(group['key_display_name']) ?? 'Unknown Source',
      publicationCount: (group['count'] as num?)?.toInt() ?? 0,
      citationCount: 0,
      isCitationEstimate: true,
    );
  }

  @override
  Future<List<({Keyword keyword, int count})>> getKeywordsByTopic({
    required String topicId,
    int limit = 8,
  }) async {
    final safeLimit = limit.clamp(1, 200);
    try {
      final response = await _apiClient.dio.get(
        '/works',
        queryParameters: {
          'filter': 'primary_topic.id:${_shortId(topicId)}',
          'group_by': 'keywords.id',
          'per_page': safeLimit,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final groups = data?['group_by'] as List<dynamic>? ?? const [];
      final items = <({Keyword keyword, int count})>[];
      for (final raw in groups) {
        if (raw is! Map<String, dynamic>) continue;
        final key = _readString(raw['key']);
        final name = _readString(raw['key_display_name']);
        if (key == null || name == null) continue;
        if (!key.contains('keywords')) continue;
        final id = key.contains('/') ? key : 'https://openalex.org/keywords/$key';
        items.add((
          keyword: Keyword(id: id, displayName: name),
          count: (raw['count'] as num?)?.toInt() ?? 0,
        ));
        if (items.length >= safeLimit) break;
      }
      return items;
    } on DioException catch (error) {
      throw _mapDioError(error);
    } catch (error) {
      throw ParsingException('Unexpected error: $error');
    }
  }

  @override
  Future<JournalSummaryModel> getJournalById(String journalId) async {
    try {
      final response = await _apiClient.dio.get(
        '/sources/${_shortId(journalId)}',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ParsingException('Invalid source response');
      }
      return JournalSummaryModel.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on ParsingException {
      rethrow;
    } catch (error) {
      throw ParsingException('Unexpected error: $error');
    }
  }

  @override
  Future<PageResult<WorkModel>> getWorksByJournal({
    required String journalId,
    String? topicId,
    int page = 1,
    int perPage = 20,
    String sort = 'cited_by_count:desc',
  }) {
    final filters = <String>[
      'primary_location.source.id:${_shortId(journalId)}',
      if (topicId != null && topicId.trim().isNotEmpty)
        'primary_topic.id:${_shortId(topicId)}',
    ];
    return _request('/works', {
      'filter': filters.join(','),
      'sort': sort,
      'page': page,
      'per_page': perPage,
    }, WorkModel.fromJson);
  }

  @override
  Future<PageResult<WorkModel>> getWorksByKeyword(
    String keywordId, {
    int page = 1,
    int perPage = 25,
    String sort = 'cited_by_count:desc',
  }) {
    return _request('/works', {
      'filter': 'keywords.id:${_keywordFilterId(keywordId)}',
      'sort': sort,
      'page': page,
      'per_page': perPage,
    }, WorkModel.fromJson);
  }

  @override
  Future<List<TrendPoint>> getKeywordTrend(String keywordId) =>
      _yearTrend('keywords.id:${_keywordFilterId(keywordId)}');

  @override
  Future<List<TrendPoint>> getTopicTrend(String topicId) =>
      _yearTrend('primary_topic.id:${_shortId(topicId)}');

  /// Số bài theo năm cho một filter bất kỳ (`group_by=publication_year`).
  Future<List<TrendPoint>> _yearTrend(String filter) async {
    try {
      final response = await _apiClient.dio.get(
        '/works',
        queryParameters: {
          'filter': filter,
          'group_by': 'publication_year',
          // per_page giới hạn SỐ NHÓM trả về — phải đủ lớn để lấy hết các năm
          // (mặc định/giá trị nhỏ chỉ trả về 1 nhóm). 200 là mức tối đa OpenAlex.
          'per_page': 200,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final groups = data?['group_by'] as List<dynamic>? ?? [];
      final points =
          groups
              .whereType<Map<String, dynamic>>()
              .map((g) {
                final year = int.tryParse('${g['key']}');
                final count = (g['count'] as num?)?.toInt() ?? 0;
                return year == null
                    ? null
                    : TrendPoint(year: year, count: count);
              })
              .whereType<TrendPoint>()
              .toList()
            ..sort((a, b) => a.year.compareTo(b.year));
      return points;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw ParsingException('Unexpected error: $e');
    }
  }

  String _shortId(String id) => id.split('/').last;

  /// OpenAlex đòi dạng `keywords/<slug>`. Nhận cả URL đầy đủ, `keywords/slug`
  /// hoặc slug trần (path param của route detail).
  String _keywordFilterId(String raw) => 'keywords/${_shortId(raw.trim())}';

  String? _readString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<PageResult<T>> _request<T>(
    String path,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _apiClient.dio.get(path, queryParameters: params);
      final data = response.data as Map<String, dynamic>?;
      final results = data?['results'] as List<dynamic>? ?? [];
      final meta = data?['meta'] as Map<String, dynamic>?;
      final total = (meta?['count'] as num?)?.toInt() ?? results.length;
      final items = results
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
      return (items: items, total: total);
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on ParsingException {
      rethrow;
    } catch (e) {
      throw ParsingException('Unexpected error: $e');
    }
  }

  Exception _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }
    return ServerException(
      e.response?.statusMessage ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
