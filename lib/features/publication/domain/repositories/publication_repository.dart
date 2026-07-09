import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/paged.dart';
import '../entities/topic.dart';
import '../entities/trend_point.dart';
import '../entities/work.dart';

abstract class PublicationRepository {
  /// Tìm/duyệt topic nghiên cứu (`/topics`), có phân trang.
  Future<Either<Failure, Paged<Topic>>> searchTopics({
    String? query,
    String sort = 'works_count:desc',
    int page = 1,
    int perPage = 25,
  });

  /// Danh sách bài báo của một topic (`/works?filter=primary_topic.id:{id}`),
  /// có phân trang.
  Future<Either<Failure, Paged<Work>>> getWorksByTopic(
    String topicId, {
    int page = 1,
    int perPage = 25,
    int? year,
    String sort = 'cited_by_count:desc',
  });

  /// Số bài báo theo năm của một topic — dữ liệu cho biểu đồ xu hướng (4.3).
  Future<Either<Failure, List<TrendPoint>>> getTopicTrend(String topicId);

  /// Chi tiết đầy đủ một bài báo theo OpenAlex work ID.
  Future<Either<Failure, Work>> getWorkById(String workId);
}
