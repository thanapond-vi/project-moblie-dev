import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keep/core/theme.dart';
import 'package:keep/l10n/gen/app_localizations.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/models/key_point.dart';
import 'package:keep/services/slm_service.dart';
import 'package:keep/widgets/score_badge.dart';

// ผลประเมินแบบใหม่: เก็บประเด็นที่เขียนถึง/ยังขาด และวงแหวนคะแนน
void main() {
  test('KeyPoint อ่านได้ทั้งรูปแบบของโมเดลและของ Firestore', () {
    final points = KeyPoint.listFrom([
      {'point': 'Founded 1882', 'importance': 'detail', 'covered': true},
      {'point': 'Plays in Burnley', 'core': true, 'covered': false},
      {'point': '  '}, // ไม่มีข้อความ → ทิ้ง
      'not a map',
    ]);
    expect(points, hasLength(2));
    expect(points.first.core, isFalse);
    expect(points.first.covered, isTrue);
    expect(points.last.core, isTrue);
    final back = KeyPoint.fromMap(points.last.toMap())!;
    expect(
      (back.point, back.core, back.covered),
      ('Plays in Burnley', true, false),
    );
  });

  test('evaluate ส่งรายการประเด็นและข้อมูลผิดกลับมาด้วย', () async {
    dotenv.loadFromString(envString: 'GROQ_API_KEY=test-key');
    final reply = {
      'keyPoints': [
        {'point': 'A', 'importance': 'core', 'covered': true, 'evidence': 'a'},
        {
          'point': 'B',
          'importance': 'detail',
          'covered': false,
          'evidence': '',
        },
      ],
      'accuracyIssues': ['wrong year', ' '],
      'aiFeedback': 'Good.',
      'tags': ['history'],
    };
    final slm = SlmService(
      client: MockClient(
        (_) async => http.Response(
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
    final result = await slm.evaluate(
      language: ContentLanguage.en,
      articleTitle: 't',
      originalContent: 'c',
      userSummary: 'a',
    );
    expect(result.keyPoints.map((p) => p.covered), [true, false]);
    expect(result.accuracyIssues, ['wrong year']);
  });

  testWidgets(
    'วงแหวนคะแนน: อ่านออกเสียงเป็นคะแนน + ระดับ และไม่ล้นที่ตัวอักษร 3 เท่า',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(3)),
            child: Scaffold(body: Center(child: ScoreRing(score: 85))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Score 85, Mastered'), findsOneWidget);
      expect(tester.getSize(find.byType(ScoreRing)), const Size(104, 104));
      handle.dispose();
    },
  );
}
