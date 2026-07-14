import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/constants/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_helpers.dart';

void main() {
  patrolTest(
    'TC8 - Profile shows authenticated user',
    ($) async {
      await ensureSignedIn($);

      await goTab($, WidgetKeys.navProfile);
      await $(WidgetKeys.profileScreen).waitUntilVisible(
        timeout: const Duration(seconds: 20),
      );
      expect($(WidgetKeys.profileUserHeader), findsOneWidget);
      expect($(WidgetKeys.profileSignOutButton), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );
}
