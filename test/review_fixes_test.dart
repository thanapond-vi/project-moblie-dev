import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/core/theme.dart';
import 'package:keep/l10n/gen/app_localizations.dart';
import 'package:keep/models/article.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/models/key_point.dart';
import 'package:keep/screens/launch_screen.dart';
import 'package:keep/services/bookmark_service.dart';
import 'package:keep/widgets/stat_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

// เทสต์ของจุดที่แก้ตาม reviewer: จำกัดขนาดข้อมูล AI, บุ๊กมาร์กไม่หายตอนโหลดซ้อน, การอ่านออกเสียง
Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Article _article(int pageId) => Article(
  sourceId: 'wikipedia',
  pageId: pageId,
  title: 'A$pageId',
  content: 'x',
  url: '',
  language: ContentLanguage.en,
);

void main() {
  test('ประเด็นจาก AI: ไม่เกิน 10 ข้อ ข้อละไม่เกิน 300 ตัวอักษร', () {
    final points = KeyPoint.listFrom([
      for (var i = 0; i < 15; i++) {'point': 'p' * 500, 'covered': true},
    ]);
    expect(points, hasLength(KeyPoint.maxPoints));
    expect(points.first.point.length, KeyPoint.maxLength + 1); // + "…"
  });

  group('BookmarkService', () {
    setUp(BookmarkService.instance.clear);

    test('กดบันทึกระหว่างที่ยังโหลดไม่เสร็จ → ไม่ลบรายการเดิม', () async {
      SharedPreferences.setMockInitialValues({
        'bookmarks_u1': '{"wikipedia:en:1": {"title": "A1"}}',
      });
      final service = BookmarkService.instance;
      final loading = service.load('u1'); // ไม่ await
      await service.toggle(_article(2));
      await loading;
      expect(service.saved.value, {'wikipedia:en:1', 'wikipedia:en:2'});
    });

    test('แยกตามบัญชี: เปลี่ยนผู้ใช้แล้วไม่เห็นบุ๊กมาร์กของคนเดิม', () async {
      SharedPreferences.setMockInitialValues({
        'bookmarks_u1': '{"wikipedia:en:1": {"title": "A1"}}',
      });
      final service = BookmarkService.instance;
      await service.load('u1');
      expect(service.isSaved(_article(1)), isTrue);
      service.clear();
      await service.load('u2');
      expect(service.saved.value, isEmpty);
    });
  });

  testWidgets('StatTile อ่านเป็นข้อความเดียว และค่าว่างอ่านว่า "no data yet"', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const Row(
          children: [
            Expanded(
              child: StatTile(
                value: 3,
                label: 'Logs saved',
                color: Colors.green,
              ),
            ),
            Expanded(
              child: StatTile(
                value: null,
                label: 'Review',
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Logs saved: 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Review: no data yet'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('หน้าเปิดแอป: โปรแกรมอ่านหน้าจอกดข้ามได้', (tester) async {
    final handle = tester.ensureSemantics();
    var done = 0;
    await tester.pumpWidget(
      _app(LaunchScreen(onDone: () => done++, sound: false)),
    );
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^KEEP')));
    expect(node.getSemanticsData().hint, 'Skip intro');
    tester.semantics.tap(find.semantics.byLabel(RegExp('^KEEP')));
    expect(done, 1);
    await tester.pump(LaunchScreen.total);
    handle.dispose();
  });
}
