import 'package:get_it/get_it.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_info.dart';
import '../../home/presentation/cubit/home_cubit.dart';
import '../../journal/presentation/cubit/journal_cubit.dart';
import '../../journal/presentation/cubit/publication_detail_cubit.dart';
import '../../keywords/domain/usecases/build_research_dashboard.dart';
import '../../keywords/presentation/cubit/research_dashboard_cubit.dart';
import '../../shared/presentation/cubit/pending_search_cubit.dart';
import '../../shared/presentation/cubit/selected_topic_cubit.dart';
import '../data/datasources/publication_remote_datasource.dart';
import '../data/repositories/publication_repository_impl.dart';
import '../domain/repositories/publication_repository.dart';
import '../domain/usecases/get_topic_trend.dart';
import '../domain/usecases/get_work_by_id.dart';
import '../domain/usecases/get_works_by_topic.dart';
import '../domain/usecases/search_topics.dart';

void initPublicationFeature(GetIt sl) {
  // Datasource
  sl.registerLazySingleton<PublicationRemoteDatasource>(
    () => PublicationRemoteDatasourceImpl(sl<ApiClient>()),
  );

  // Repository
  sl.registerLazySingleton<PublicationRepository>(
    () => PublicationRepositoryImpl(
      datasource: sl<PublicationRemoteDatasource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SearchTopics(sl<PublicationRepository>()));
  sl.registerLazySingleton(() => GetWorksByTopic(sl<PublicationRepository>()));
  sl.registerLazySingleton(() => GetWorkById(sl<PublicationRepository>()));
  sl.registerLazySingleton(() => GetTopicTrend(sl<PublicationRepository>()));
  sl.registerLazySingleton(() => const BuildResearchDashboard());

  // Shared state (singleton — cùng instance cho mọi tab)
  sl.registerSingleton<SelectedTopicCubit>(SelectedTopicCubit());
  sl.registerSingleton<PendingSearchCubit>(PendingSearchCubit());

  // Cubits (factory = fresh state mỗi lần tạo tab)
  sl.registerFactory(() => HomeCubit(sl<SearchTopics>()));
  sl.registerFactory(
    () => JournalCubit(sl<GetWorksByTopic>(), sl<GetTopicTrend>()),
  );
  sl.registerFactory(
    () => ResearchDashboardCubit(
      sl<GetWorksByTopic>(),
      sl<BuildResearchDashboard>(),
    ),
  );
  sl.registerFactory(() => PublicationDetailCubit(sl<GetWorkById>()));
}
