import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/models/article.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/screens/profile_screen.dart';
import 'package:keep/services/sources/wikipedia_source.dart';

// ทดสอบหัวข้อบทความ และการแสดงอีเมลยาว (ไม่ต้องใช้ Firebase/อินเทอร์เน็ต)
void main() {
  test('cleanExtractWithHeadings คืนเฉพาะหัวข้อที่เก็บไว้', () {
    final long = 'ก' * 250;
    final r = WikipediaSource.cleanExtractWithHeadings(
      'บทนำ\n\n== ประวัติ ==\n$long\n\n== ผู้เล่น ==\nณ 31 สิงหาคม\n\n'
      '== เกียรติประวัติ ==\n=== ลีก ===\n$long\n\n== อ้างอิง ==\nx',
    );
    expect(r.headings, ['ประวัติ', 'เกียรติประวัติ', 'ลีก']);
  });

  test('Article เก็บหัวข้อลง JSON และเซสชันเก่าที่ไม่มีหัวข้อยังเปิดได้', () {
    const article = Article(
      sourceId: 'wikipedia',
      pageId: 1,
      title: 'A',
      content: 'intro\n\nHistory\n\ntext',
      url: '',
      language: ContentLanguage.en,
      headings: ['History'],
    );
    final restored = Article.fromJson(article.toJson());
    expect(restored.headings, ['History']);
    expect(restored.isHeading('History'), isTrue);
    expect(restored.isHeading('text'), isFalse);

    final old = Article.fromJson(article.toJson()..remove('headings'));
    expect(old.headings, isEmpty);
  });

  group('EmailText', () {
    Widget host(String email, {double width = 160}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: EmailText(email)),
        ),
      ),
    );

    testWidgets('อีเมลยาว: ส่วนโดเมนแสดงเต็มเสมอ ไม่ล้น', (tester) async {
      await tester.pumpWidget(host('averyveryverylongname@gmail.com'));
      expect(tester.takeException(), isNull);
      expect(find.text('@gmail.com'), findsOneWidget);
      expect(find.text('averyveryverylongname'), findsOneWidget);
    });

    testWidgets('screen reader อ่านอีเมลเต็ม', (tester) async {
      await tester.pumpWidget(host('averyveryverylongname@gmail.com'));
      expect(
        find.bySemanticsLabel('averyveryverylongname@gmail.com'),
        findsOneWidget,
      );
    });

    testWidgets('ไม่มี @ → แสดงเป็นข้อความเดียว', (tester) async {
      await tester.pumpWidget(host('no-at-sign'));
      expect(find.text('no-at-sign'), findsOneWidget);
    });
  });
}
