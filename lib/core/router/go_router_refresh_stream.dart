import 'dart:async';

import 'package:flutter/foundation.dart';

/// Chuyển một [Stream] thành [Listenable] để `GoRouter.refreshListenable`
/// re-evaluate `redirect` mỗi khi auth state đổi.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
