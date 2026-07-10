import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/datasources/profile_local_datasource.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../domain/repositories/profile_repository.dart';

final profileLocalDatasourceProvider = Provider<ProfileLocalDatasource>(
  (ref) => ProfileLocalDatasourceImpl(ref.watch(sharedPreferencesProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileLocalDatasourceProvider)),
);
