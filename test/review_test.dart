import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:keep/core/theme.dart';
import 'package:keep/l10n/gen/app_localizations.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/models/key_point.dart';
import 'package:keep/models/review_schedule.dart';
import 'package:keep/models/study_log.dart';
import 'package:keep/screens/review_screen.dart';
import 'package:keep/screens/review_session_screen.dart';
import 'package:keep/services/study_log_repository.dart';

// แท็บทบทวนแบบกล่องเลื่อนขั้น (Leitner): ตารางวัน, รายการที่ถึงกำหนด, ขั้นตอนนึก → เฉลย → ให้คะแนน
final _now = DateTime(2026, 11, 2, 9);

StudyLog _log(
  String id, {
  required DateTime read,
  int box = 0,
  DateTime? next,
  int total = 0,
  int passed = 0,
  List<KeyPoint> points = const [],
  String? question,
}) => StudyLog(
  id: id,
  userId: 'u',
  articleTitle: 'Article $id',
  articleUrl: '',
  originalContent: '',
  userSummary: 'My summary of $id',
  readingTimeMinutes: 5,
  tags: const [],
  language: ContentLanguage.en,
  sourceId: 'wikipedia',
  pageId: 1,
  aiScore: 70,
  aiFeedback: null,
  createdAt: read,
  updatedAt: null,
  keyPoints: points,
  recallQuestion: question,
  reviewBox: box,
  nextReviewAt: next,
  reviewsTotal: total,
  reviewsPassed: passed,
);

/// จดว่าบันทึกผลทบทวนอะไรไปบ้าง แทน Firestore จริง
class _FakeRepo implements StudyLogRepository {
  final saved = <(String, int, DateTime, bool)>[];

  @override
  Future<void> recordReview({
    required String logId,
    required int box,
    required DateTime nextReviewAt,
    required bool passed,
  }) async => saved.add((logId, box, nextReviewAt, passed));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.dark(),
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('ReviewSchedule', () {
    test('อ่านแล้วถึงรอบทบทวนครั้งแรกวันถัดไป', () {
      final log = _log('a', read: DateTime(2026, 11, 1, 22));
      expect(ReviewSchedule.dueDay(log), DateTime(2026, 11, 2));
      expect(ReviewSchedule.isDue(log, _now), isTrue);
      expect(
        ReviewSchedule.isDue(_log('b', read: DateTime(2026, 11, 2)), _now),
        isFalse,
      );
    });

    test(
      'เลื่อนกล่อง: ลืม → 1, ยาก → เดิม, ดี → +1, ง่าย → +2 (ไม่เกิน 5)',
      () {
        expect(ReviewSchedule.nextBox(3, ReviewRating.again), 1);
        expect(ReviewSchedule.nextBox(3, ReviewRating.hard), 3);
        expect(ReviewSchedule.nextBox(3, ReviewRating.good), 4);
        expect(ReviewSchedule.nextBox(4, ReviewRating.easy), 5);
        expect(ReviewSchedule.nextBox(5, ReviewRating.good), 5);
        // ยังไม่เคยทบทวน (กล่อง 0)
        expect(ReviewSchedule.nextBox(0, ReviewRating.hard), 1);
        expect(ReviewSchedule.nextBox(0, ReviewRating.good), 2);
      },
    );

    test('วันครบกำหนดถัดไปตามระยะของกล่อง 1/3/7/14/30', () {
      expect(ReviewSchedule.nextDue(1, _now), DateTime(2026, 11, 3));
      expect(ReviewSchedule.nextDue(3, _now), DateTime(2026, 11, 9));
      expect(ReviewSchedule.nextDue(5, _now), DateTime(2026, 12, 2));
    });

    test('เรียงคิว: เลยกำหนดนานสุดก่อน แล้วกล่องต่ำก่อน', () {
      final logs = [
        _log('new', read: DateTime(2026, 11, 1)), // ครบกำหนดวันนี้ กล่อง 0
        _log(
          'late',
          read: DateTime(2026, 10, 1),
          box: 3,
          next: DateTime(2026, 10, 30),
        ),
        _log(
          'box4',
          read: DateTime(2026, 10, 1),
          box: 4,
          next: DateTime(2026, 11, 2),
        ),
        _log(
          'later',
          read: DateTime(2026, 10, 1),
          box: 2,
          next: DateTime(2026, 11, 5),
        ),
      ];
      expect(ReviewSchedule.dueList(logs, _now).map((l) => l.id), [
        'late',
        'new',
        'box4',
      ]);
      expect(ReviewSchedule.upcoming(logs, _now).map((l) => l.id), ['later']);
      expect(ReviewSchedule.boxCounts(logs), [1, 1, 1, 1, 0]);
    });

    test('อัตราทบทวนสำเร็จ', () {
      expect(ReviewSchedule.successRate([_log('a', read: _now)]), isNull);
      expect(
        ReviewSchedule.successRate([
          _log('a', read: _now, total: 3, passed: 2),
          _log('b', read: _now, total: 1, passed: 1),
        ]),
        75,
      );
    });
  });

  testWidgets('แท็บทบทวน: บอกจำนวนที่ต้องทบทวน กดเริ่มได้ และมีกล่อง 5 ใบ', (
    tester,
  ) async {
    List<StudyLog>? started;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: ReviewBody(
            now: _now,
            onStart: (q) => started = q,
            logs: [
              _log('a', read: DateTime(2026, 10, 31)),
              _log(
                'b',
                read: DateTime(2026, 10, 1),
                box: 2,
                next: DateTime(2026, 11, 6),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 article to review'), findsOneWidget);
    expect(find.text('Box 5'), findsOneWidget);
    await tester.tap(find.text('Review'));
    expect(started?.map((l) => l.id), ['a']);
    await tester.scrollUntilVisible(
      find.text('Article b'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Article b'), findsOneWidget);
  });

  testWidgets('ยังไม่มีบันทึก: ชวนไปอ่านก่อน ไม่มีปุ่มเริ่ม', (tester) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: ReviewBody(now: _now, onStart: (_) {}, logs: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Read an article and save'), findsOneWidget);
    expect(find.text('Review'), findsNothing);
  });

  testWidgets(
    'ทบทวน: นึก → เฉลย → ให้คะแนน "ดี" → บันทึกกล่องใหม่ แล้วไปเรื่องถัดไป',
    (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(
        _app(
          ReviewSessionScreen(
            repository: repo,
            queue: [
              _log(
                'a',
                read: DateTime(2026, 10, 31),
                question: 'Why does the Moon have phases?',
                points: const [
                  KeyPoint(
                    point: 'Sunlight on half the Moon',
                    core: true,
                    covered: true,
                  ),
                ],
              ),
              _log('b', read: DateTime(2026, 10, 31)),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Why does the Moon have phases?'), findsOneWidget);
      // ยังไม่เฉลย = ยังไม่เห็นคำตอบ และยังให้คะแนนไม่ได้
      expect(find.textContaining('Sunlight on half'), findsNothing);
      expect(find.text('How well did you remember?'), findsNothing);

      await tester.tap(find.text('Reveal key points'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sunlight on half'), findsOneWidget);

      // "ดี" จากกล่อง 0 → กล่อง 2 (อีก 3 วัน)
      await tester.ensureVisible(find.bySemanticsLabel('Good, in 3 days'));
      await tester.tap(find.bySemanticsLabel('Good, in 3 days'));
      await tester.pumpAndSettle();
      expect(repo.saved.single.$1, 'a');
      expect(repo.saved.single.$2, 2);
      expect(repo.saved.single.$4, isTrue);

      // เรื่องที่ 2 ไม่มีคำถามเดิม → คำถามทั่วไป, ไม่มีประเด็น → เฉลยด้วยคำสรุปเดิม
      expect(find.text('Review · 2/2'), findsOneWidget);
      expect(find.textContaining('What do you remember'), findsOneWidget);
      await tester.tap(find.text('Reveal key points'));
      await tester.pumpAndSettle();
      expect(find.text('My summary of b'), findsOneWidget);
    },
  );
}
