import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/journal/presentation/pages/journal_page.dart';
import '../../features/journal/presentation/pages/publication_detail_page.dart';
import '../../features/keywords/presentation/pages/research_dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
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
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                builder: (context, state) => const JournalPage(),
                routes: [
                  GoRoute(
                    path: 'detail/:workId',
                    builder: (context, state) {
                      final workId = state.pathParameters['workId']!;
                      final preview =
                          state.extra is Work ? state.extra as Work : null;
                      return PublicationDetailPage(
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
                builder: (context, state) => const ResearchDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
