import 'package:flutter_test/flutter_test.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/models/period_stats.dart';
import 'package:keep/models/study_log.dart';

// สถิติแท็บ "สถิติ": ช่วงเวลา, เทียบช่วงก่อนหน้า, แท่งรายวัน/สัปดาห์, หมวด, ปฏิทิน, วันติดกัน
StudyLog _log(
  DateTime at, {
  int minutes = 5,
  int? score,
  List<String> tags = const [],
}) => StudyLog(
  id: '${at.microsecondsSinceEpoch}',
  userId: 'u',
  articleTitle: 'T${at.day}',
  articleUrl: '',
  originalContent: '',
  userSummary: '',
  readingTimeMinutes: minutes,
  tags: tags,
  language: ContentLanguage.en,
  sourceId: 'wikipedia',
  pageId: at.day,
  aiScore: score,
  aiFeedback: null,
  createdAt: at,
  updatedAt: null,
);

void main() {
  final now = DateTime(2026, 11, 2, 20); // จันทร์

  test('7 วัน: นับเฉพาะในช่วง และเทียบกับ 7 วันก่อนหน้า', () {
    final stats = PeriodStats.from(
      [
        _log(DateTime(2026, 11, 2, 9), minutes: 10, score: 90),
        _log(
          DateTime(2026, 10, 27, 9),
          minutes: 20,
          score: 70,
        ), // วันแรกของช่วง
        _log(DateTime(2026, 10, 26, 9), minutes: 15, score: 40), // ช่วงก่อนหน้า
        _log(DateTime(2026, 10, 1), minutes: 99), // นอกทั้งสองช่วง
      ],
      StatsRange.week,
      now: now,
    );
    expect(stats.minutes, 30);
    expect(stats.articles, 2);
    expect(stats.averageScore, 80);
    expect(stats.previousMinutes, 15);
    expect(stats.previousArticles, 1);
    expect(stats.previousAverageScore, 40);
    expect(stats.buckets, hasLength(7));
    expect(stats.buckets.first.start, DateTime(2026, 10, 27));
    expect(stats.buckets.first.minutes, 20);
    expect(stats.buckets.last.minutes, 10);
    expect(stats.weekly, isFalse);
  });

  test('คะแนนเรียงตามเวลา และข้ามบันทึกที่ยังไม่มีคะแนน', () {
    final stats = PeriodStats.from(
      [
        _log(DateTime(2026, 11, 2), score: 50),
        _log(DateTime(2026, 10, 30), score: 80),
        _log(DateTime(2026, 10, 31)),
      ],
      StatsRange.week,
      now: now,
    );
    expect(stats.scores.map((p) => p.score), [80, 50]);
  });

  test('ทั้งหมด: ไม่มีช่วงก่อนหน้า และเกิน 60 วันรวมเป็นรายสัปดาห์', () {
    final stats = PeriodStats.from(
      [
        _log(DateTime(2026, 6, 3), minutes: 7),
        _log(DateTime(2026, 11, 2), minutes: 3),
      ],
      StatsRange.all,
      now: now,
    );
    expect(stats.previousMinutes, isNull);
    expect(stats.weekly, isTrue);
    expect(stats.buckets.first.start.weekday, DateTime.monday);
    expect(stats.buckets.map((b) => b.minutes).reduce((a, b) => a + b), 10);
  });

  test('หมวด: เรียงจากมากไปน้อย เกิน 5 หมวดรวมเป็น "อื่นๆ"', () {
    final logs = [
      for (var i = 0; i < 3; i++)
        _log(DateTime(2026, 11, 1, i), tags: ['history'], score: 60),
      for (final t in ['a', 'b', 'c', 'd', 'e', 'f'])
        _log(DateTime(2026, 11, 2, t.codeUnitAt(0) % 20), tags: [t]),
    ];
    final topics = PeriodStats.from(logs, StatsRange.month, now: now).topics;
    expect(topics.first.tag, 'history');
    expect(topics.first.count, 3);
    expect(topics.first.averageScore, 60);
    expect(topics, hasLength(PeriodStats.maxTopics + 1));
    expect(topics.last.tag, isNull); // อื่นๆ
    expect(topics.last.count, 2);
  });

  test('ปฏิทิน: รวมนาทีต่อวัน ย้อนหลังไม่เกิน 12 สัปดาห์', () {
    final cal = PeriodStats.calendar([
      _log(DateTime(2026, 11, 2, 8), minutes: 4),
      _log(DateTime(2026, 11, 2, 21), minutes: 6),
      _log(DateTime(2026, 6, 1), minutes: 9), // เก่าเกินปฏิทิน
    ], now: now);
    expect(cal[DateTime(2026, 11, 2)], 10);
    expect(cal.length, 1);
  });

  test('วันติดกันยาวที่สุด (ข้ามเดือนได้)', () {
    expect(
      PeriodStats.longestStreak([
        _log(DateTime(2026, 9, 29)),
        _log(DateTime(2026, 9, 30)),
        _log(DateTime(2026, 10, 1)),
        _log(DateTime(2026, 10, 1, 22)), // วันเดียวกัน ไม่นับซ้ำ
        _log(DateTime(2026, 10, 5)),
      ]),
      3,
    );
    expect(PeriodStats.longestStreak([]), 0);
  });
}
