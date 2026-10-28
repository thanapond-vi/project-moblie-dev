import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keep/models/article.dart';
import 'package:keep/models/article_tag.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/models/reading_session.dart';
import 'package:keep/models/reading_topic.dart';
import 'package:keep/models/user_profile.dart';
import 'package:keep/services/settings_service.dart';
import 'package:keep/services/sources/article_source.dart';
import 'package:keep/services/sources/wikipedia_source.dart';
import 'package:keep/widgets/animated_counter.dart';
import 'package:keep/widgets/reading_lamp.dart';

// ทดสอบส่วนที่ไม่ต้องใช้ Firebase/อินเทอร์เน็ต รันด้วย `flutter test`
void main() {
  const article = Article(
    sourceId: 'wikipedia',
    pageId: 42,
    title: '大胆查理',
    content: 'ย่อหน้าแรก\n\nย่อหน้าที่สอง\nย่อหน้าที่สาม',
    url: 'https://zh.wikipedia.org/wiki/x',
    language: ContentLanguage.zh,
    topic: 'history',
  );

  test('Article แบ่งย่อหน้าถูก (ข้ามบรรทัดว่าง)', () {
    expect(article.paragraphs, [
      'ย่อหน้าแรก',
      'ย่อหน้าที่สอง',
      'ย่อหน้าที่สาม',
    ]);
  });

  test(
    'ReadingSession แปลงเป็น JSON แล้วกลับมาได้ค่าเดิม (ใช้เก็บใน SharedPreferences)',
    () {
      final session = ReadingSession(
        article: article,
        limitSeconds: 1800,
        elapsedSeconds: 125,
        stage: SessionStage.summarizing,
        draftSummary: 'ร่าง',
        updatedAt: DateTime(2026, 10, 25),
      );
      final restored = ReadingSession.fromJson(session.toJson());
      expect(restored.article.title, '大胆查理');
      expect(restored.article.language, ContentLanguage.zh);
      expect(restored.article.topic, 'history');
      expect(restored.article.readKey, 'wikipedia:zh:42');
      expect(restored.stage, SessionStage.summarizing);
      expect(restored.remainingSeconds, 1800 - 125);
      expect(restored.readingMinutes, 3); // 125 วินาที ปัดขึ้นเป็น 3 นาที
      expect(restored.draftSummary, 'ร่าง');
    },
  );

  test('ค่าที่ไม่รู้จัก/ข้อมูลเก่า แปลงเป็นค่า default ไม่แครช', () {
    expect(
      ContentLanguage.fromCode(null),
      ContentLanguage.en,
    ); // ผู้ใช้ใหม่ = ENG
    expect(ContentLanguage.fromCode('xx'), ContentLanguage.en);
    // บันทึก/เซสชันเก่าก่อนมีหลายภาษา = ภาษาไทย
    expect(
      ContentLanguage.fromCode(null, fallback: ContentLanguage.th),
      ContentLanguage.th,
    );
    expect(ArticleTag.fromId(null), isNull);
    // เซสชันเก่าใช้ key "category" แทน "topic"
    expect(
      Article.fromJson({'title': 'x', 'category': 'science'}).topic,
      'science',
    );
  });

  test('ภาษาเรียง ENG ก่อน และแสดงเป็นคำ ไม่มีธง', () {
    expect(ContentLanguage.values.map((l) => l.label), [
      'English',
      'Chinese',
      'Thai',
    ]);
  });

  test('แท็ก: ตัดซ้ำ ตัดค่าว่าง และเก็บไม่เกิน 3', () {
    expect(
      ArticleTag.normalize([
        'History',
        'history',
        '',
        'กาแฟ',
        'science',
        'culture',
      ]),
      ['history', 'กาแฟ', 'science'],
    );
  });

  test('หมวดที่เลือกก่อนสุ่ม: สุ่มทุกหมวด / หมวดยอดฮิต / ค้นเอง', () {
    expect(ReadingTopic.any.isAny, isTrue);
    expect(ReadingTopic.any.tag, isNull);
    expect(const ReadingTopic.preset(ArticleTag.culture).tag, 'culture');
    expect(const ReadingTopic.search('  กาแฟ ').tag, 'กาแฟ');
    expect(const ReadingTopic.search('   ').isAny, isTrue);
    expect(ReadingTopic.fromTag('history').preset, ArticleTag.history);
    expect(ReadingTopic.fromTag('กาแฟ').query, 'กาแฟ');
  });

  testWidgets('ReadingLamp วาดได้ทั้งตอนแตะและตอนหายใจ โดยไม่มี error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const Scaffold(
          body: ReadingLampBackground(active: true, child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // ลากนิ้ว → แสงค่อยๆ ตาม
    final gesture = await tester.startGesture(const Offset(50, 50));
    await gesture.moveTo(const Offset(300, 500));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();

    // ปล่อยไว้เกิน 3 วินาที → เข้าโหมดหายใจ
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReadingLamp หยุด Ticker เองเมื่อแสงนิ่งและไม่ได้จับเวลา', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingLampBackground(active: false, child: SizedBox.expand()),
        ),
      ),
    );
    // ถ้า Ticker ไม่หยุด pumpAndSettle จะรอไม่จบ (มีเฟรมใหม่ตลอด) แล้ว test fail
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test('UserProfile ถอด base64 ของรูปได้ และข้อมูลเสียไม่ทำให้แครช', () {
    final ok = UserProfile(
      nickname: 'ภู',
      preset: AvatarPreset.fromId('cover_owl'),
      avatarBase64: 'AQID', // = bytes [1, 2, 3]
    );
    expect(ok.avatarBytes, [1, 2, 3]);
    expect(ok.preset, AvatarPreset.owl);
    expect(ok.preset.asset, 'assets/avatars/cover_owl.png');

    final broken = UserProfile(
      nickname: 'ภู',
      preset: AvatarPreset.fromId('ไม่มีแบบนี้'),
      avatarBase64: '%%%ไม่ใช่ base64',
    );
    expect(broken.avatarBytes, isNull); // ใช้รูปตัวละครแทน
    expect(
      broken.preset,
      AvatarPreset.cat,
    ); // id ที่ไม่รู้จัก → ตัวละครเริ่มต้น
    expect(broken.copyWith(clearAvatar: true).avatarBase64, isNull);
  });

  test('ภาษา: "ไว้ทีหลัง" ใช้ภาษาเดิมต่อ แต่เปิดแอปใหม่ได้ภาษาใหม่', () async {
    SharedPreferences.setMockInitialValues({}); // จำลอง SharedPreferences ว่าง
    final settings = SettingsService.instance;
    await settings.load();
    expect(settings.appLanguage.value, ContentLanguage.en); // ผู้ใช้ใหม่ = ENG
    expect(settings.ttsLanguage.value, ContentLanguage.en);

    await settings.saveLanguages(
      app: ContentLanguage.th,
      article: ContentLanguage.zh,
      tts: null, // AUTO
      applyNow: false,
    );
    expect(settings.appLanguage.value, ContentLanguage.en); // ยังเป็นภาษาเดิม
    expect(settings.pendingLanguages.value?.app, ContentLanguage.th);

    await settings.load(); // = เปิดแอปครั้งถัดไป
    expect(settings.appLanguage.value, ContentLanguage.th);
    expect(settings.articleLanguage.value, ContentLanguage.zh);
    expect(settings.ttsLanguage.value, isNull); // AUTO
  });

  testWidgets('การ์ดสถิตินับตัวเลขจาก 0 ไปจนถึงค่าจริง', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatRevealCard(
            icon: Icons.timer_outlined,
            label: 'Total reading',
            value: 1909,
            unit: 'min',
            caption: 'All time',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400)); // ระหว่างนับ
    expect(find.textContaining('1909'), findsNothing);
    await tester.pumpAndSettle(); // นับจบ
    expect(find.textContaining('1909'), findsOneWidget);
    expect(find.text('Total reading'), findsOneWidget); // ป้ายพิมพ์ครบ
  });

  group('WikipediaSource (จำลอง Wikipedia ด้วย MockClient ไม่ต้องใช้เน็ต)', () {
    // หัวข้อที่มีบทความทั้งหมดแค่ 2 เรื่อง (totalhits = 2)
    MockClient fakeWikipedia() => MockClient((request) async {
      final q = request.url.queryParameters;
      if (q['list'] == 'search') {
        return http.Response(
          jsonEncode({
            'query': {
              'searchinfo': {'totalhits': 2},
              'search': [
                {'pageid': 1, 'title': 'A', 'size': 30000},
                {'pageid': 2, 'title': 'B', 'size': 30000},
              ],
            },
          }),
          200,
        );
      }
      final id = q['pageids'];
      return http.Response(
        jsonEncode({
          'query': {
            'pages': [
              {
                'pageid': int.parse(id!),
                'title': 'Page $id',
                'fullurl': 'https://en.wikipedia.org/wiki/$id',
                'extract': 'x' * 4000,
              },
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    test('ข้ามบทความที่อ่านแล้ว', () async {
      final article = await WikipediaSource(client: fakeWikipedia())
          .fetchRandomArticle(
            language: ContentLanguage.en,
            topic: const ReadingTopic.search('tiny topic'),
            excludeKeys: {'wikipedia:en:1'},
          );
      expect(article.pageId, 2);
      expect(article.topic, 'tiny topic');
    });

    test('อ่านครบทุกเรื่องแล้ว → TopicExhaustedException', () async {
      expect(
        WikipediaSource(client: fakeWikipedia()).fetchRandomArticle(
          language: ContentLanguage.en,
          topic: const ReadingTopic.search('tiny topic'),
          excludeKeys: {'wikipedia:en:1', 'wikipedia:en:2'},
        ),
        throwsA(isA<TopicExhaustedException>()),
      );
    });

    test('ตัดเทมเพลตวิกิที่ครบคู่ออกทั้งก้อน (รวมที่ซ้อนกัน)', () {
      expect(
        WikipediaSource.cleanExtract(
          'ไม่แพ้ 30 นัด{{efn|สถิตินี้ถูกทำลายโดย{{sfn|Arsenal}}}} และชนะเลิศ',
        ),
        'ไม่แพ้ 30 นัด และชนะเลิศ',
      );
    });

    test('เทมเพลตไม่มีตัวปิด: ลบเฉพาะ "{{efn|" แต่เก็บข้อความไว้', () {
      expect(
        WikipediaSource.cleanExtract(
          'ไม่แพ้ 30 นัด{{efn|สถิตินี้ถูกทำลายโดยอาร์เซนอล',
        ),
        'ไม่แพ้ 30 นัด สถิตินี้ถูกทำลายโดยอาร์เซนอล',
      );
      expect(WikipediaSource.cleanExtract('จบแล้ว}} ต่อ'), 'จบแล้ว ต่อ');
    });

    test(
      'หัวข้อ wiki: ตัดหัวข้อที่เหลือแค่คำบรรยายตาราง และตัดตั้งแต่อ้างอิง',
      () {
        final long = 'ก' * 250;
        final cleaned = WikipediaSource.cleanExtract(
          'บทนำ\n\n== ประวัติ ==\n$long\n\n'
          '== ผู้เล่น ==\nณ 31 สิงหาคม ค.ศ.2025\n\n'
          '== เกียรติประวัติ ==\n=== ลีก ===\n$long\n\n'
          '== หมายเหตุ ==\n\n== อ้างอิง ==\nบรรณานุกรม',
        );
        expect(
          cleaned,
          'บทนำ\n\nประวัติ\n\n$long\n\nเกียรติประวัติ\n\nลีก\n\n$long',
        );
        expect(cleaned, isNot(contains('ผู้เล่น')));
        expect(cleaned, isNot(contains('==')));
      },
    );

    test('ข้อความปกติไม่ถูกแก้ และยังตัดส่วนอ้างอิงท้ายบทความ', () {
      expect(
        WikipediaSource.cleanExtract('เนื้อหา {a} (b)\nอ้างอิง\nลิงก์'),
        'เนื้อหา {a} (b)',
      );
    });
  });

  test(
    'ผู้ใช้รุ่นเก่าที่ไม่เคยตั้งภาษา TTS → AUTO (อ่านตามภาษาบทความ)',
    () async {
      SharedPreferences.setMockInitialValues({'contentLanguage': 'th'});
      await SettingsService.instance.load();
      expect(
        SettingsService.instance.articleLanguage.value,
        ContentLanguage.th,
      );
      expect(SettingsService.instance.ttsLanguage.value, isNull);
    },
  );

  testWidgets(
    'ค่าเปลี่ยนหลังเปิดตัวจบ → นับต่อจากเลขเดิม ไม่เล่นการ์ดใหม่ทั้งใบ',
    (tester) async {
      Widget card(int value) => MaterialApp(
        home: Scaffold(
          body: StatRevealCard(
            icon: Icons.timer_outlined,
            label: 'Total',
            value: value,
            unit: 'min',
            caption: 'All time',
          ),
        ),
      );
      await tester.pumpWidget(card(100));
      await tester.pumpAndSettle();
      await tester.pumpWidget(card(130));
      await tester.pump(const Duration(milliseconds: 50));
      // การ์ดไม่ได้หดกลับไปเริ่มใหม่ (ป้ายยังแสดงครบ)
      expect(find.text('Total'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.textContaining('130'), findsOneWidget);
    },
  );
}
