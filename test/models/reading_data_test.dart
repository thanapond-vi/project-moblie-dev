import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keep/core/app_exception.dart';
import 'package:keep/models/article.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/models/reading_session.dart';
import 'package:keep/services/slm_service.dart';

// ข้อมูลใหม่ของหน้าอ่าน: รูปนำ, เวลาอ่านโดยประมาณ, คำถามชวนนึกจาก AI
Article _article({String content = 'x', ContentLanguage? language}) => Article(
  sourceId: 'wikipedia',
  pageId: 7,
  title: 'Moon',
  content: content,
  url: 'https://en.wikipedia.org/wiki/Moon',
  language: language ?? ContentLanguage.en,
  imageUrl: 'https://upload.wikimedia.org/moon.jpg',
);

SlmService _groq(String content) => SlmService(
  client: MockClient(
    (request) async => http.Response(
      jsonEncode({
        'model': 'qwen/test',
        'choices': [
          {
            'message': {'content': content},
          },
        ],
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  ),
);

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'GROQ_API_KEY=test-key'));

  test('เซสชันเก็บรูปนำและคำถามชวนนึกไว้ เปิดแอปใหม่ได้ค่าเดิม', () {
    final session = ReadingSession(
      article: _article(),
      limitSeconds: 600,
      elapsedSeconds: 30,
      stage: SessionStage.reading,
      draftSummary: '',
      updatedAt: DateTime(2026, 11, 1),
    ).copyWith(recallQuestion: 'Why does the Moon have phases?');
    final back = ReadingSession.fromJson(
      jsonDecode(jsonEncode(session.toJson())) as Map<String, dynamic>,
    );
    expect(back.recallQuestion, 'Why does the Moon have phases?');
    expect(back.article.imageUrl, 'https://upload.wikimedia.org/moon.jpg');
    // copyWith อื่นๆ ไม่ลบคำถามทิ้ง
    expect(back.copyWith(elapsedSeconds: 40).recallQuestion, isNotNull);
  });

  test('เซสชันเก่าที่ไม่มีรูป/คำถาม → null ไม่แครช', () {
    final json = _article().toJson()..remove('imageUrl');
    expect(Article.fromJson(json).imageUrl, isNull);
  });

  test('เวลาอ่านโดยประมาณ: จีนช้ากว่า (ตัวอักษรแน่นกว่า)', () {
    expect(_article(content: 'a' * 2500).estimatedMinutes, 3);
    expect(
      _article(
        content: '字' * 700,
        language: ContentLanguage.zh,
      ).estimatedMinutes,
      2,
    );
    expect(_article(content: '').estimatedMinutes, 1);
  });

  group('SlmService.recallQuestion', () {
    test('ตัด <think> และเครื่องหมายคำพูด เหลือคำถามบรรทัดเดียว', () async {
      final q =
          await _groq(
            '<think>plan</think>\n"Why does the Moon show phases?"\nextra',
          ).recallQuestion(
            title: 'Moon',
            reference: 'text',
            language: ContentLanguage.en,
          );
      expect(q, 'Why does the Moon show phases?');
    });

    test('ตอบว่างเปล่า → AppException (หน้าอ่านจะใช้คำถามทั่วไปแทน)', () {
      expect(
        _groq('   ').recallQuestion(
          title: 'Moon',
          reference: 'text',
          language: ContentLanguage.en,
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}
