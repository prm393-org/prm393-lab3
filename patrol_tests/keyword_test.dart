import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/constants/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_helpers.dart';

void main() {
  patrolTest(
    'TC6 - Keywords tab shows stats and list',
    ($) async {
      await ensureSignedIn($);
      await selectFirstTopicDashboard($);

      await goTab($, WidgetKeys.navKeywords);

      await $(WidgetKeys.dashboardKpiGrid).waitUntilExists(
        timeout: const Duration(seconds: 120),
      );
      expect($(WidgetKeys.dashboardKpiGrid), findsOneWidget);

      // Chờ list keyword có trong tree rồi mới scroll dọc (tránh scroll ngang).
      await $(WidgetKeys.dashboardKeywordRow(0)).waitUntilExists(
        timeout: const Duration(seconds: 90),
      );
      await $(WidgetKeys.dashboardKeywordRow(0)).scrollTo(
        view: $(WidgetKeys.keywordsList),
        scrollDirection: AxisDirection.down,
        maxScrolls: 25,
      );
      expect($(WidgetKeys.dashboardKeywordRow(0)), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );

  patrolTest(
    'TC7 - Open keyword detail',
    ($) async {
      await ensureSignedIn($);
      await selectFirstTopicDashboard($);

      await goTab($, WidgetKeys.navKeywords);
      await waitKeywordsLoaded($);
      await tapKey($, WidgetKeys.dashboardKeywordRow(0));

      await $(WidgetKeys.keywordDetailScreen).waitUntilExists(
        timeout: const Duration(seconds: 60),
      );
      expect($(WidgetKeys.keywordDetailHeader), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );
}
