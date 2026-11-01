import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/services/slm_service.dart';

// ทดสอบการให้คะแนนแบบไล่เช็กประเด็น (จำลอง Groq ด้วย MockClient ไม่ต้องใช้เน็ต)
void main() {
  const summary =
      'Burnley was founded in 1882. It won the league in 1920-21 and 1959-60, '
      'and plays at Turf Moor.';

  Map<String, dynamic> point(
    String text, {
    bool covered = true,
    String evidence = '',
    String importance = 'core',
  }) => {
    'point': text,
    'importance': importance,
    'covered': covered,
    'evidence': evidence,
  };

  group('SlmService.scoreOf', () {
    test('ครอบคลุมทุกประเด็นพร้อมหลักฐานจริง → 100', () {
      expect(
        SlmService.scoreOf(
          [
            point('founded', evidence: 'founded in 1882'),
            point('titles', evidence: 'won the league in 1920-21 and 1959-60,'),
            point('stadium', evidence: 'Turf Moor.', importance: 'detail'),
          ],
          const [],
          summary,
        ),
        100,
      );
    });

    test('core หนัก 2 เท่าของ detail', () {
      // ได้ core 1 ข้อ (2) จาก core 1 + detail 1 (รวม 3) = 67
      expect(
        SlmService.scoreOf(
          [
            point('founded', evidence: 'Founded in 1882'),
            point('rival', covered: false, importance: 'detail'),
          ],
          const [],
          summary,
        ),
        67,
      );
    });

    test('หลักฐานหลายช่วงคั่นด้วย "..." → นับเต็มถ้าเจอครบทุกช่วง', () {
      expect(
        SlmService.scoreOf(
          [point('facts', evidence: 'founded in 1882... plays at Turf Moor')],
          const [],
          summary,
        ),
        100,
      );
      expect(
        SlmService.scoreOf(
          [point('facts', evidence: 'founded in 1882… plays at Anfield')],
          const [],
          summary,
        ),
        50,
      );
    });

    test('ครอบคลุมแต่หลักฐานไม่มีในคำสรุป → ได้ครึ่งเดียว', () {
      expect(
        SlmService.scoreOf(
          [point('founded', evidence: 'established in 1882')],
          const [],
          summary,
        ),
        50,
      );
    });

    test('ข้อมูลผิดหักข้อละ 10 สูงสุด 30', () {
      final points = [point('founded', evidence: 'founded in 1882')];
      expect(SlmService.scoreOf(points, ['wrong year'], summary), 90);
      expect(
        SlmService.scoreOf(points, ['a', 'b', 'c', 'd', 'e'], summary),
        70,
      );
    });

    test('ไม่มีรายการประเด็น → null (ให้ใช้คะแนนที่โมเดลตอบแทน)', () {
      expect(SlmService.scoreOf(null, null, summary), isNull);
      expect(SlmService.scoreOf(const [], null, summary), isNull);
    });
  });

  group('SlmService.evaluate', () {
    setUpAll(() => dotenv.loadFromString(envString: 'GROQ_API_KEY=test-key'));

    SlmService fakeGroq(Map<String, dynamic> reply) => SlmService(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'model': 'qwen/test',
            'choices': [
              {
                'message': {'content': jsonEncode(reply)},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    Future<int> scoreFor(Map<String, dynamic> reply) async =>
        (await fakeGroq(reply).evaluate(
          language: ContentLanguage.en,
          articleTitle: 'Burnley F.C.',
          originalContent: 'article',
          userSummary: summary,
        )).score;

    test('คะแนนคำนวณจากรายการประเด็น ไม่เชื่อ aiScore ที่โมเดลเดามา', () async {
      expect(
        await scoreFor({
          'aiScore': 40,
          'keyPoints': [point('founded', evidence: 'founded in 1882')],
          'accuracyIssues': [],
          'aiFeedback': 'Good.',
          'tags': ['history'],
        }),
        100,
      );
    });

    test('โมเดลตอบแบบเก่า (ไม่มี keyPoints) → ใช้ aiScore', () async {
      expect(await scoreFor({'aiScore': 72, 'aiFeedback': 'OK'}), 72);
    });

    test('โดน 429 แล้วลองใหม่เองตาม retry-after จนได้ผล', () async {
      var calls = 0;
      final service = SlmService(
        client: MockClient((request) async {
          calls++;
          if (calls == 1) {
            return http.Response('', 429, headers: {'retry-after': '0'});
          }
          return http.Response(
            jsonEncode({
              'model': 'qwen/test',
              'choices': [
                {
                  'message': {
                    'content': jsonEncode({'aiScore': 60, 'aiFeedback': 'OK'}),
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      final r = await service.evaluate(
        language: ContentLanguage.en,
        articleTitle: 't',
        originalContent: 'a',
        userSummary: summary,
      );
      expect(r.score, 60);
      expect(calls, 2);
    });
  });

  group('SlmService.retryWait', () {
    test('อ่านวินาทีจาก retry-after', () {
      expect(SlmService.retryWait('2'), const Duration(seconds: 2));
      expect(SlmService.retryWait('0.5'), const Duration(milliseconds: 500));
    });

    test(
      'ไม่มีค่า อ่านไม่ได้ หรือนานเกิน 10 วินาที → null (ให้ผู้ใช้กดลองใหม่เอง)',
      () {
        expect(SlmService.retryWait(null), isNull);
        expect(SlmService.retryWait('soon'), isNull);
        expect(SlmService.retryWait('30'), isNull);
      },
    );
  });
}
