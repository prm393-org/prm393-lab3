import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/journal/presentation/screens/journal_detail_screen.dart';
import '../../features/journal/presentation/screens/publication_detail_screen.dart';
import '../../features/keywords/presentation/screens/research_dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/publication/domain/entities/work.dart';
import '../../features/publication/domain/entities/journal_summary.dart';
import '../../firebase/firebase_providers.dart';
import '../navigation/main_scaffold.dart';
import 'go_router_refresh_stream.dart';

/// Router có auth guard: chưa login → `/login`, đã login vào `/login` → `/home`.
final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  final refresh = GoRouterRefreshStream(auth.authStateChanges);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      // Đọc `currentUser` đồng bộ — không dùng StreamProvider ở đây.
      // Khi refreshListenable fire, StreamProvider có thể chưa kịp update
      // → redirect đọc user=null và kẹt ở /login dù Firebase đã login.
      final isLoggedIn = auth.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !loggingIn) return '/login';
      if (isLoggedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
                      final preview = state.extra is Work
                          ? state.extra as Work
                          : null;
                      return PublicationDetailScreen(
                        workId: workId,
                        preview: preview,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'journal-detail/:journalId',
                    builder: (context, state) {
                      final journalId = state.pathParameters['journalId']!;
                      final preview = state.extra is JournalSummary
                          ? state.extra as JournalSummary
                          : null;
                      return JournalDetailScreen(
                        journalId: journalId,
                        preview: preview,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'publication/:workId',
                        builder: (context, state) {
                          final workId = state.pathParameters['workId']!;
                          final preview = state.extra is Work
                              ? state.extra as Work
                              : null;
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
});

/// Legacy namespace — dùng [goRouterProvider] trong app.
abstract final class AppRouter {
  AppRouter._();
}
