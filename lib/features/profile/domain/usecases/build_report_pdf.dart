import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../keywords/domain/entities/research_dashboard_summary.dart';

/// Dựng file PDF báo cáo cho topic đang xem (FR 4.8 — Report Export).
///
/// Trả về bytes để [StorageService] upload; không đụng tới Firebase ở đây nên
/// test được mà không cần khởi tạo Firebase.
class BuildReportPdf {
  const BuildReportPdf();

  Future<Uint8List> call(ResearchDashboardSummary summary) async {
    final doc = pw.Document();
    final generatedAt = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(
                  _ascii(summary.topic.displayName),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),
              ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
        ),
        build: (context) => [
          _title(summary, generatedAt),
          pw.SizedBox(height: 18),
          _kpiTable(summary),
          pw.SizedBox(height: 18),
          if (summary.yearlyTrend.isNotEmpty) ...[
            _section('Publication trend'),
            _trendTable(summary),
            pw.SizedBox(height: 18),
          ],
          if (summary.topJournals.isNotEmpty) ...[
            _section('Top journals'),
            _rankTable(summary.topJournals, 'Journal'),
            pw.SizedBox(height: 18),
          ],
          if (summary.topAuthors.isNotEmpty) ...[
            _section('Top authors'),
            _rankTable(summary.topAuthors, 'Author'),
            pw.SizedBox(height: 18),
          ],
          if (summary.topKeywords.isNotEmpty) ...[
            _section('Top keywords'),
            _rankTable(summary.topKeywords, 'Keyword'),
            pw.SizedBox(height: 18),
          ],
          if (summary.topPapers.isNotEmpty) ...[
            _section('Most cited papers'),
            _papersTable(summary),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _title(ResearchDashboardSummary summary, DateTime generatedAt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Journal Trend Analyzer',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _ascii(summary.topic.displayName),
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Research report - generated ${_formatDate(generatedAt)} - '
          'sample of ${summary.sampleSize} most-cited papers',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Divider(color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _section(String label) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      label.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
      ),
    ),
  );

  pw.Widget _kpiTable(ResearchDashboardSummary summary) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Metric', 'Value'],
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {1: pw.Alignment.centerRight},
      data: [
        ['Total publications', '${summary.totalPublications}'],
        ['Total citations (sample)', '${summary.totalCitations}'],
        ['Average citations', summary.averageCitations.toStringAsFixed(1)],
        ['Most active year', '${summary.mostActiveYear ?? 'N/A'}'],
        ['Top journal', _ascii(summary.topJournal?.name ?? 'N/A')],
        ['Top author', _ascii(summary.topAuthor?.name ?? 'N/A')],
      ],
    );
  }

  pw.Widget _trendTable(ResearchDashboardSummary summary) {
    // Chỉ lấy 12 năm gần nhất cho vừa trang.
    final points = summary.yearlyTrend.length > 12
        ? summary.yearlyTrend.sublist(summary.yearlyTrend.length - 12)
        : summary.yearlyTrend;

    return pw.TableHelper.fromTextArray(
      headers: const ['Year', 'Papers'],
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {1: pw.Alignment.centerRight},
      data: [
        for (final point in points) ['${point.year}', '${point.count}'],
      ],
    );
  }

  pw.Widget _rankTable(List<RankedResearchItem> items, String label) {
    return pw.TableHelper.fromTextArray(
      headers: ['#', label, 'Papers'],
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(52),
      },
      cellAlignments: {0: pw.Alignment.center, 2: pw.Alignment.centerRight},
      data: [
        for (var i = 0; i < items.length; i++)
          ['${i + 1}', _ascii(items[i].name), '${items[i].count}'],
      ],
    );
  }

  pw.Widget _papersTable(ResearchDashboardSummary summary) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Title', 'Year', 'Citations'],
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      columnWidths: {
        0: const pw.FlexColumnWidth(),
        1: const pw.FixedColumnWidth(40),
        2: const pw.FixedColumnWidth(56),
      },
      cellAlignments: {
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
      },
      data: [
        for (final paper in summary.topPapers)
          [
            _ascii(paper.title),
            '${paper.publicationYear ?? 'n/a'}',
            '${paper.citedByCount}',
          ],
      ],
    );
  }

  /// Lối vào để test [_ascii] — phần sanitize là chỗ dễ vỡ nhất của file này.
  static String debugAscii(String input) => _ascii(input);

  static String _formatDate(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  /// Font mặc định của PDF (Helvetica) **không hỗ trợ Unicode** — mà dữ liệu
  /// OpenAlex thì đầy tên tác giả có dấu, tiêu đề CJK, dấu gạch ngang dài.
  /// Nhúng TTF Unicode sẽ phải thêm asset font vài trăm KB, nên ở đây quy hết
  /// về ASCII: bỏ dấu chữ Latin (á → a), còn lại thay bằng '?'.
  static String _ascii(String input) {
    const punctuation = {
      '–': '-',
      '—': '-',
      '‐': '-',
      '‑': '-',
      '·': '-',
      '‘': "'",
      '’': "'",
      '“': '"',
      '”': '"',
      '…': '...',
      '×': 'x',
      ' ': ' ',
    };

    // Bỏ dấu: đủ phủ tiếng Việt và các ngôn ngữ Latin châu Âu.
    const folding = {
      'aàáâãäåāăạảấầẩẫậắằẳẵặ': 'a',
      'eèéêëēĕėęěẹẻẽếềểễệ': 'e',
      'iìíîïĩīĭįıịỉ': 'i',
      'oòóôõöøōŏőơọỏốồổỗộớờởỡợ': 'o',
      'uùúûüũūŭůűųưụủứừửữự': 'u',
      'yýÿỳỵỷỹ': 'y',
      'cçćĉċč': 'c',
      'dđďḑ': 'd',
      'nñńņňn': 'n',
      'sśŝşš': 's',
      'zźżž': 'z',
      'gğĝġģ': 'g',
      'lĺļľł': 'l',
      'rŕŗř': 'r',
      'tţťŧ': 't',
    };

    final buffer = StringBuffer();
    for (final rune in input.runes) {
      // ASCII in được — đường đi thường gặp nhất, thoát sớm.
      if (rune >= 0x20 && rune <= 0x7E) {
        buffer.writeCharCode(rune);
        continue;
      }

      final char = String.fromCharCode(rune);
      final mapped = punctuation[char];
      if (mapped != null) {
        buffer.write(mapped);
        continue;
      }

      final lower = char.toLowerCase();
      var folded = false;
      for (final entry in folding.entries) {
        if (entry.key.contains(lower)) {
          final base = entry.value;
          buffer.write(char == lower ? base : base.toUpperCase());
          folded = true;
          break;
        }
      }

      // Còn lại (CJK, emoji, ký hiệu toán học…) không vẽ được bằng Helvetica.
      if (!folded) buffer.write('?');
    }
    return buffer.toString();
  }
}
