import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/models/reading_topic.dart';
import 'package:keep/services/slm_service.dart';
import 'package:keep/services/sources/wikipedia_source.dart';

// ทดสอบเรียก API จริง (ต้องต่ออินเทอร์เน็ตและใช้โควตา Groq) จึงข้ามไว้ในการรันปกติ
// รันด้วย: LIVE=1 flutter test test/live
// ส่ง MODEL=<ชื่อโมเดล> เพื่อลองโมเดลอื่นโดยไม่ต้องแก้ .env
final Object _liveSkip = Platform.environment['LIVE'] == '1'
    ? false
    : 'เรียก API จริง: รันด้วย LIVE=1 flutter test test/live';

void main() => group('API จริง', skip: _liveSkip, () {
  setUpAll(() {
    var env = File('.env').readAsStringSync();
    final model = Platform.environment['MODEL'];
    if (model != null) {
      env = env.replaceAll(
        RegExp(r'^GROQ_MODEL=.*$', multiLine: true),
        'GROQ_MODEL=$model',
      );
    }
    dotenv.loadFromString(envString: env);
  });

  test(
    'Wikipedia: สุ่มบทความได้และยาวพอ',
    () async {
      // LANG_CODE=en|zh|th และ TOPIC=<id หมวดยอดฮิต หรือคำค้นเอง> เช่น TOPIC=science, TOPIC=coffee
      final a = await WikipediaSource().fetchRandomArticle(
        language: ContentLanguage.fromCode(Platform.environment['LANG_CODE']),
        topic: ReadingTopic.fromTag(Platform.environment['TOPIC']),
        excludeKeys: const {},
      );
      // ignore: avoid_print
      print(
        '${a.language.code}/${a.topic ?? 'any'} | ${a.title} | ${a.content.length} chars | ${a.url}',
      );
      expect(a.content.length, greaterThan(500));
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );

  test(
    'SLM: ประเมินคำสรุปได้คะแนนและ feedback',
    () async {
      final sw = Stopwatch()..start();
      final r = await SlmService().evaluate(
        language: ContentLanguage.fromCode(Platform.environment['LANG_CODE']),
        articleTitle: 'กรุงเทพมหานคร',
        originalContent:
            'กรุงเทพมหานคร เป็นเมืองหลวงและเมืองที่มีประชากรมากที่สุดของประเทศไทย ตั้งอยู่บริเวณสามเหลี่ยมปากแม่น้ำเจ้าพระยา '
            'มีแม่น้ำเจ้าพระยาไหลผ่านใจกลางเมือง แบ่งเป็นฝั่งพระนครและฝั่งธนบุรี ก่อตั้งเป็นราชธานีในปี พ.ศ. 2325 '
            'เป็นศูนย์กลางเศรษฐกิจ การเมือง และการท่องเที่ยว',
        userSummary:
            'กรุงเทพเป็นเมืองหลวงของไทย มีคนอยู่เยอะที่สุด อยู่ริมแม่น้ำเจ้าพระยา เป็นศูนย์กลางเศรษฐกิจและการท่องเที่ยวของประเทศ',
      );
      // ignore: avoid_print
      print(
        '[${r.model}] ${sw.elapsed.inMilliseconds}ms score=${r.score} tags=${r.tags}\n${r.feedback}',
      );
      expect(r.score, inInclusiveRange(0, 100));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test('AI: คำทักทายประจำวัน 1 ประโยค', () async {
    final g = await SlmService().dailyGreeting(
      language: ContentLanguage.fromCode(Platform.environment['LANG_CODE']),
      date: DateTime.now(),
    );
    // ignore: avoid_print
    print('greeting: $g');
    expect(g, isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 40)));
});
