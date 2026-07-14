import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/core/constants/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_helpers.dart';

void main() {
  patrolTest(
    'TC1 - Google Sign-In navigates to Home',
    ($) async {
      await launchApp($);
      await signInWithGoogle($);
      expect($(WidgetKeys.homeScreen), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );

  patrolTest(
    'TC11 - Logout redirects to Login',
    ($) async {
      await ensureSignedIn($);

      await goTab($, WidgetKeys.navProfile);
      await $(WidgetKeys.profileSignOutButton).waitUntilVisible(
        timeout: const Duration(seconds: 20),
      );
      await $(WidgetKeys.profileSignOutButton).tap();

      // Dialog confirm — nút FilledButton "Sign out"
      await $('Sign out').last.waitUntilVisible();
      await $('Sign out').last.tap();

      await $(WidgetKeys.loginScreen).waitUntilVisible(
        timeout: const Duration(seconds: 30),
      );
      expect($(WidgetKeys.loginGoogleButton), findsOneWidget);
    },
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
  );
}
