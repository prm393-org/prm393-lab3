import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
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

  /// Chi tiết một bài báo (`/works/{id}`) — phục vụ màn Publication Detail.
  Future<WorkModel> getWorkById(String workId);

  Future<List<JournalSummaryModel>> getJournalsByTopic({
    required String topicId,
    int limit = 10,
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
  static const _citationSampleSize = 200;

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
      final validGroups = groups
          .whereType<Map<String, dynamic>>()
          .where((group) => _shortId('${group['key']}').startsWith('S'))
          .take(safeLimit);

      return Future.wait(
        validGroups.map((group) async {
          final sourceId = '${group['key']}';
          final publicationCount = (group['count'] as num?)?.toInt() ?? 0;
          final metadata = await getJournalById(sourceId);
          final citationMetrics = await _getTopicCitationMetrics(
            topicId: topicId,
            journalId: sourceId,
            publicationCount: publicationCount,
          );
          return metadata.withTopicMetrics(
            publicationCount: publicationCount,
            citationCount: citationMetrics.citations,
            isCitationEstimate: citationMetrics.isEstimate,
            fallbackDisplayName: _readString(group['key_display_name']),
          );
        }),
      );
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

  Future<({int citations, bool isEstimate})> _getTopicCitationMetrics({
    required String topicId,
    required String journalId,
    required int publicationCount,
  }) async {
    if (publicationCount <= 0) {
      return (citations: 0, isEstimate: false);
    }
    final sampleSize = publicationCount.clamp(1, _citationSampleSize);
    final params = <String, dynamic>{
      'filter':
          'primary_topic.id:${_shortId(topicId)},primary_location.source.id:${_shortId(journalId)}',
      'per_page': sampleSize,
      'select': 'id,cited_by_count',
    };
    final isEstimate = publicationCount > _citationSampleSize;
    if (isEstimate) {
      params
        ..['sample'] = _citationSampleSize
        ..['seed'] = _stableSeed(journalId);
    }

    final result = await _request('/works', params, WorkModel.fromJson);
    final sampleCitations = result.items.fold<int>(
      0,
      (total, work) => total + work.citedByCount,
    );
    if (!isEstimate || result.items.isEmpty) {
      return (citations: sampleCitations, isEstimate: false);
    }
    final estimated = (sampleCitations / result.items.length * publicationCount)
        .round();
    return (citations: estimated, isEstimate: true);
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
  Future<List<TrendPoint>> getTopicTrend(String topicId) async {
    try {
      final response = await _apiClient.dio.get(
        '/works',
        queryParameters: {
          'filter': 'primary_topic.id:${_shortId(topicId)}',
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

  int _stableSeed(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

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
