import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/constants/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_helpers.dart';

void main() {
  patrolTest(
    'TC2 - Topic search shows results',
    ($) async {
      await ensureSignedIn($);
      await searchTopic($);
      expect($(WidgetKeys.homeTopic(0)), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );

  patrolTest(
    'TC3 - Open publication detail',
    ($) async {
      await ensureSignedIn($);
      await selectFirstTopicDashboard($);
      await openFirstPublication($);

      await $(WidgetKeys.publicationDetailScreen).waitUntilExists(
        timeout: const Duration(seconds: 60),
      );
      expect($(WidgetKeys.publicationDetailTitle), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );
}
