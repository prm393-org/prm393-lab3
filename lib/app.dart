import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/di/profile_di.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/profile/presentation/cubit/profile_state.dart';
import 'features/shared/presentation/cubit/pending_search_cubit.dart';
import 'features/shared/presentation/cubit/selected_topic_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SelectedTopicCubit>(
          create: (_) => getIt<SelectedTopicCubit>(),
        ),
        BlocProvider<PendingSearchCubit>(
          create: (_) => getIt<PendingSearchCubit>(),
        ),
        BlocProvider<ProfileCubit>(
          create: (_) {
            ensureProfileFeatureRegistered(getIt);
            return getIt<ProfileCubit>()..load();
          },
        ),
      ],
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (prev, curr) => prev.themeMode != curr.themeMode,
        builder: (context, profileState) {
          final brightness = switch (profileState.themeMode) {
            ThemeMode.dark => Brightness.dark,
            ThemeMode.light => Brightness.light,
            ThemeMode.system =>
              WidgetsBinding.instance.platformDispatcher.platformBrightness,
          };
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.overlayStyle(brightness),
            child: MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: profileState.themeMode,
              routerConfig: AppRouter.router,
            ),
          );
        },
      ),
    );
  }
}
