import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/firebase/analytics_service.dart';

void main() {
  test('logViewJournal emits view_journal with required parameters', () async {
    String? eventName;
    Map<String, Object>? eventParameters;
    final service = AnalyticsService.forTesting((name, parameters) async {
      eventName = name;
      eventParameters = parameters;
    });

    await service.logViewJournal(journalName: 'IEEE Access', journalId: 'S1');

    expect(eventName, 'view_journal');
    expect(eventParameters?['journal_name'], 'IEEE Access');
    expect(eventParameters?['journal_id'], 'S1');
  });
}
