import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../keywords/domain/usecases/build_research_dashboard.dart';
import '../data/datasources/publication_remote_datasource.dart';
import '../data/repositories/publication_repository_impl.dart';
import '../domain/repositories/publication_repository.dart';
import '../domain/usecases/get_topic_trend.dart';
import '../domain/usecases/get_work_by_id.dart';
import '../domain/usecases/get_works_by_topic.dart';
import '../domain/usecases/search_topics.dart';

/// Tầng Service của MVVM: datasource → repository → use case.
/// Trước đây đăng ký trong `publication_di.dart` bằng get_it.

final publicationRemoteDatasourceProvider = Provider<PublicationRemoteDatasource>(
  (ref) => PublicationRemoteDatasourceImpl(ref.watch(apiClientProvider)),
);

final publicationRepositoryProvider = Provider<PublicationRepository>(
  (ref) => PublicationRepositoryImpl(
    datasource: ref.watch(publicationRemoteDatasourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  ),
);

final searchTopicsProvider = Provider<SearchTopics>(
  (ref) => SearchTopics(ref.watch(publicationRepositoryProvider)),
);

final getWorksByTopicProvider = Provider<GetWorksByTopic>(
  (ref) => GetWorksByTopic(ref.watch(publicationRepositoryProvider)),
);

final getWorkByIdProvider = Provider<GetWorkById>(
  (ref) => GetWorkById(ref.watch(publicationRepositoryProvider)),
);

final getTopicTrendProvider = Provider<GetTopicTrend>(
  (ref) => GetTopicTrend(ref.watch(publicationRepositoryProvider)),
);

final buildResearchDashboardProvider =
    Provider<BuildResearchDashboard>((ref) => const BuildResearchDashboard());
