import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/constants/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_helpers.dart';

void main() {
  patrolTest(
    'TC9 - Export PDF uploads to Storage and shows URL',
    ($) async {
      await ensureSignedIn($);
      await selectFirstTopicDashboard($);

      await goTab($, WidgetKeys.navProfile);
      await tapKey($, WidgetKeys.profileExportPdf);

      await $(WidgetKeys.profileReportUrl).waitUntilExists(
        timeout: const Duration(seconds: 120),
      );
      expect($(WidgetKeys.profileReportUrl), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );
}
