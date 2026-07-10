import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/journal/presentation/screens/publication_detail_screen.dart';
import '../../features/keywords/presentation/screens/research_dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/publication/domain/entities/work.dart';
import '../navigation/main_scaffold.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                builder: (context, state) => const JournalScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:workId',
                    builder: (context, state) {
                      final workId = state.pathParameters['workId']!;
                      final preview =
                          state.extra is Work ? state.extra as Work : null;
                      return PublicationDetailScreen(
                        workId: workId,
                        preview: preview,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/keywords',
                builder: (context, state) => const ResearchDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
