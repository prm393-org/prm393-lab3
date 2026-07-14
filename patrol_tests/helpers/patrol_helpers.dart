import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/bootstrap.dart';
import 'package:journal_trend_analyzer/core/constants/widget_keys.dart';
import 'package:patrol/patrol.dart';

/// Topic dùng chung cho các TC cần dashboard (journals / keywords / export).
const kPatrolTopicQuery = 'machine learning';

/// Email Google trên emulator — override:
/// `patrol test --dart-define=PATROL_GOOGLE_EMAIL=you@gmail.com ...`
String get patrolGoogleEmail => const String.fromEnvironment(
  'PATROL_GOOGLE_EMAIL',
  defaultValue: '',
);

Future<void> launchApp(PatrolIntegrationTester $) async {
  final app = await createApp();
  await $.pumpWidget(app);
  await $.pump(const Duration(seconds: 2));
}

Future<void> signInWithGoogle(PatrolIntegrationTester $) async {
  if ($(WidgetKeys.homeScreen).evaluate().isNotEmpty) return;

  await $(WidgetKeys.loginGoogleButton).waitUntilVisible(
    timeout: const Duration(seconds: 30),
  );
  await $(WidgetKeys.loginGoogleButton).tap();
  await $.pump(const Duration(seconds: 2));

  // ignore: deprecated_member_use
  final email = patrolGoogleEmail;
  try {
    if (email.isNotEmpty) {
      // ignore: deprecated_member_use
      await $.native.tap(
        Selector(textContains: email),
        timeout: const Duration(seconds: 20),
      );
    } else {
      // ignore: deprecated_member_use
      await $.native.tap(
        Selector(textContains: '@'),
        timeout: const Duration(seconds: 20),
      );
    }
  } catch (_) {
    // Một số máy chỉ có 1 account và tự tiếp tục.
  }

  await $(WidgetKeys.homeScreen).waitUntilVisible(
    timeout: const Duration(seconds: 90),
  );
}

Future<void> ensureSignedIn(PatrolIntegrationTester $) async {
  await launchApp($);
  await signInWithGoogle($);
}

Future<void> searchTopic(
  PatrolIntegrationTester $, {
  String query = kPatrolTopicQuery,
}) async {
  await $(WidgetKeys.homeSearchField).waitUntilVisible();
  await $(WidgetKeys.homeSearchField).enterText(query);
  await $.tester.testTextInput.receiveAction(TextInputAction.search);
  await $.pump(const Duration(seconds: 2));

  FocusManager.instance.primaryFocus?.unfocus();
  await $.pump(const Duration(seconds: 1));

  // SliverList không hit-testable — đợi item rồi scroll.
  await $(WidgetKeys.homeTopic(0)).waitUntilExists(
    timeout: const Duration(seconds: 90),
  );
  await $(WidgetKeys.homeTopic(0)).scrollTo();
}

/// Search + chọn topic + đợi KPI dashboard (không dùng home_dashboard visible).
Future<void> selectFirstTopicDashboard(PatrolIntegrationTester $) async {
  await searchTopic($);
  await $(WidgetKeys.homeTopic(0)).tap();
  await $.pump(const Duration(seconds: 2));

  await $(WidgetKeys.homeKpiTotalPublications).waitUntilExists(
    timeout: const Duration(seconds: 90),
  );
  await $(WidgetKeys.homeKpiTotalPublications).scrollTo();
}

/// SliverList.builder chỉ build item trong viewport — phải scroll mới có key.
Future<void> openFirstPublication(PatrolIntegrationTester $) async {
  await $(WidgetKeys.homePublication(0)).scrollTo(
    view: $(WidgetKeys.homeScreen),
    maxScrolls: 40,
  );
  await $(WidgetKeys.homePublication(0)).tap();
}

Future<void> goTab(PatrolIntegrationTester $, Key tabKey) async {
  await $(tabKey).tap();
  await $.pump(const Duration(milliseconds: 800));
}

Future<void> tapKey(PatrolIntegrationTester $, Key key) async {
  await $(key).scrollTo();
  await $(key).tap();
}

Future<void> waitJournalLoaded(PatrolIntegrationTester $) async {
  await $(WidgetKeys.journalsKpiStrip).waitUntilExists(
    timeout: const Duration(seconds: 90),
  );
  await $(WidgetKeys.journalCard(0)).scrollTo(
    view: $(WidgetKeys.journalsScreen),
    maxScrolls: 30,
  );
}

Future<void> waitKeywordsLoaded(PatrolIntegrationTester $) async {
  await $(WidgetKeys.dashboardKpiGrid).waitUntilExists(
    timeout: const Duration(seconds: 120),
  );

  // Đợi keyword CÓ TRONG TREE trước — không scrollTo khi Found 0 (Patrol sẽ
  // kéo lung tung, kể cả trục ngang trên chart).
  await $(WidgetKeys.dashboardKeywordRow(0)).waitUntilExists(
    timeout: const Duration(seconds: 90),
  );

  // Chỉ cuộn dọc trên ListView Keywords.
  await $(WidgetKeys.dashboardKeywordRow(0)).scrollTo(
    view: $(WidgetKeys.keywordsList),
    scrollDirection: AxisDirection.down,
    maxScrolls: 25,
    settlePolicy: SettlePolicy.trySettle,
  );
}
