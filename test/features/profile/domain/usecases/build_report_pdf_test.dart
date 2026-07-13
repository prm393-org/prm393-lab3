import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/features/keywords/domain/entities/research_dashboard_summary.dart';
import 'package:journal_trend_analyzer/features/profile/domain/usecases/build_report_pdf.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/author.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/topic.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/trend_point.dart';
import 'package:journal_trend_analyzer/features/publication/domain/entities/work.dart';

ResearchDashboardSummary summaryWith({
  String topicName = 'Machine Learning',
  List<Work> topPapers = const [],
  List<RankedResearchItem> topAuthors = const [],
}) {
  return ResearchDashboardSummary(
    topic: Topic(id: 'https://openalex.org/T1', displayName: topicName),
    totalPublications: 1200,
    totalCitations: 8000,
    averageCitations: 66.6,
    mostActiveYear: 2024,
    sampleSize: 100,
    yearlyTrend: const [
      TrendPoint(year: 2023, count: 40),
      TrendPoint(year: 2024, count: 60),
    ],
    citationTrend: const [],
    topJournals: const [RankedResearchItem(name: 'Nature', count: 12)],
    topAuthors: topAuthors,
    topKeywords: const [RankedResearchItem(name: 'deep learning', count: 30)],
    topInstitutions: const [],
    authorStats: const [],
    institutionStats: const [],
    journalStats: const [],
    emergingKeywords: const [],
    frontierKeywords: const [],
    topPapers: topPapers,
    scatterPapers: const [],
  );
}

void main() {
  test('produces a valid PDF document', () async {
    final bytes = await const BuildReportPdf()(summaryWith());

    expect(bytes, isNotEmpty);
    // Magic number của file PDF.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('survives non-Latin titles and authors from OpenAlex', () async {
    // Helvetica (font mặc định của PDF) không hỗ trợ Unicode: không sanitize
    // thì text ra ô vuông đúng lúc user bấm Export.
    final bytes = await const BuildReportPdf()(
      summaryWith(
        topicName: 'Máy học – Trí tuệ nhân tạo',
        topAuthors: const [RankedResearchItem(name: '张伟', count: 9)],
        topPapers: const [
          Work(
            id: 'W1',
            title: '深層学習 — a study of “neural” networks × transformers',
            publicationYear: 2024,
            citedByCount: 500,
            authors: [Author(displayName: 'Ada')],
            isOpenAccess: true,
          ),
        ],
      ),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('folds accents and drops unsupported glyphs before drawing', () {
    // Nội dung text được ghi thẳng (không nén) vào PDF, nên tìm được trong bytes.
    String render(String value) => BuildReportPdf.debugAscii(value);

    expect(render('Máy học – Trí tuệ'), 'May hoc - Tri tue');
    expect(render('Erdős “quoted” × 2'), 'Erdos "quoted" x 2');
    expect(render('深層学習'), '????');
    // Không còn ký tự nào nằm ngoài ASCII in được.
    expect(
      render('Zoë · café — 深層').runes.every((r) => r >= 0x20 && r <= 0x7E),
      isTrue,
    );
  });
}
