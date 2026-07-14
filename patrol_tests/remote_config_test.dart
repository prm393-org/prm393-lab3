import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/constants/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_helpers.dart';

void main() {
  patrolTest(
    'TC10 - Remote Config values are displayed',
    ($) async {
      await ensureSignedIn($);

      await goTab($, WidgetKeys.navProfile);
      await $(WidgetKeys.profileMaxJournals).scrollTo();
      await $(WidgetKeys.profileMaxJournals).waitUntilVisible(
        timeout: const Duration(seconds: 20),
      );
      expect($(WidgetKeys.profileMaxJournals), findsOneWidget);
      expect($(WidgetKeys.profileMaxKeywords), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );
}
