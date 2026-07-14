import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/constants/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_helpers.dart';

void main() {
  patrolTest(
    'TC4 - Journals tab shows stats and list',
    ($) async {
      await ensureSignedIn($);
      await selectFirstTopicDashboard($);

      await goTab($, WidgetKeys.navJournal);
      await waitJournalLoaded($);
      expect($(WidgetKeys.journalsKpiStrip), findsOneWidget);
      expect($(WidgetKeys.journalCard(0)), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );

  patrolTest(
    'TC5 - Open journal detail',
    ($) async {
      await ensureSignedIn($);
      await selectFirstTopicDashboard($);

      await goTab($, WidgetKeys.navJournal);
      await waitJournalLoaded($);
      await tapKey($, WidgetKeys.journalCard(0));

      await $(WidgetKeys.journalDetailScreen).waitUntilExists(
        timeout: const Duration(seconds: 60),
      );
      expect($(WidgetKeys.journalDetailIdentity), findsOneWidget);
      expect($(WidgetKeys.journalTotalPublications), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );
}
