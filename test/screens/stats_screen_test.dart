import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:keep/core/theme.dart';
import 'package:keep/l10n/gen/app_localizations.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/models/period_stats.dart';
import 'package:keep/models/study_log.dart';
import 'package:keep/screens/stats_screen.dart';
import 'package:keep/widgets/charts.dart';

// แท็บสถิติ: แสดงกราฟจากข้อมูลจำลอง, สถานะว่าง, ดูเป็นตาราง, ตัวอักษร 3 เท่า
final _now = DateTime(2026, 11, 2, 20);

StudyLog _log(
  int daysAgo, {
  int minutes = 12,
  int? score,
  String tag = 'history',
}) => StudyLog(
  id: '$daysAgo-$minutes',
  userId: 'u',
  articleTitle: 'Article $daysAgo',
  articleUrl: '',
  originalContent: '',
  userSummary: '',
  readingTimeMinutes: minutes,
  tags: [tag],
  language: ContentLanguage.en,
  sourceId: 'wikipedia',
  pageId: daysAgo,
  aiScore: score,
  aiFeedback: null,
  createdAt: DateTime(2026, 11, 2 - daysAgo, 10),
  updatedAt: null,
);

Widget _app(List<StudyLog> logs, {double textScale = 1}) {
  var range = StatsRange.week;
  return MaterialApp(
    theme: AppTheme.dark(),
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => StatsBody(
            logs: logs,
            range: range,
            now: _now,
            onRange: (r) => setState(() => range = r),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  final logs = [
    _log(0, score: 85),
    _log(2, minutes: 20, score: 55, tag: 'science'),
    _log(9, minutes: 8, score: 70),
  ];

  testWidgets('มีข้อมูล: แสดงกราฟเวลาอ่าน คะแนน ปฏิทิน และหมวด', (
    tester,
  ) async {
    await tester.pumpWidget(_app(logs));
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byType(ScoreLineChart), findsOneWidget);
    // เทียบกับ 7 วันก่อนหน้า: ช่วงนี้ 32 นาที ช่วงก่อน 8 นาที
    expect(find.text('↑ 24'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('↑ 24 from last period')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Topics you read'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(ReadingCalendar), findsOneWidget);
    expect(find.byType(TopicBar), findsNWidgets(2));
  });

  testWidgets('สลับเป็นตาราง: เห็นค่าเป็นตัวหนังสือ', (tester) async {
    await tester.pumpWidget(_app(logs));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show as table').first);
    await tester.pumpAndSettle();
    expect(find.text('20 min'), findsWidgets);
    expect(find.byTooltip('Show as chart'), findsOneWidget);
  });

  testWidgets('ช่วงนี้ไม่มีการอ่าน: ข้อความว่าง แต่ยังเห็นปฏิทิน', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_log(20)]));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing read in this period'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
    expect(find.byType(ReadingCalendar), findsOneWidget);
  });

  testWidgets('ตัวอักษร 3 เท่า: ไม่ล้น', (tester) async {
    await tester.pumpWidget(_app(logs, textScale: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('แตะแท่งกราฟ: บรรทัดด้านบนบอกวันและนาที', (tester) async {
    await tester.pumpWidget(_app(logs));
    await tester.pumpAndSettle();
    final chart = tester.getRect(find.byType(BarChart));
    // แท่งสุดท้าย = วันนี้ (12 นาที)
    await tester.tapAt(Offset(chart.right - 10, chart.center.dy));
    await tester.pump();
    expect(find.textContaining('12 min'), findsWidgets);
  });
}
