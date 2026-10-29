import 'package:flutter_test/flutter_test.dart';
import 'package:keep/models/content_language.dart';
import 'package:keep/models/reading_stats.dart';
import 'package:keep/models/study_log.dart';
import 'package:keep/widgets/score_badge.dart';

// สถิติหน้า Home: วันติดกัน เป้าหมายวันนี้ และคะแนนเฉลี่ย (คำนวณจากประวัติในเครื่อง)
StudyLog _log(DateTime at, {int minutes = 5, int? score}) => StudyLog(
  id: '${at.millisecondsSinceEpoch}',
  userId: 'u',
  articleTitle: 't',
  articleUrl: '',
  originalContent: '',
  userSummary: '',
  readingTimeMinutes: minutes,
  tags: const [],
  language: ContentLanguage.th,
  sourceId: 'wikipedia',
  pageId: 1,
  aiScore: score,
  aiFeedback: null,
  createdAt: at,
  updatedAt: null,
);

void main() {
  final now = DateTime(2026, 11, 2, 20);

  test('อ่านวันนี้ เมื่อวาน และข้ามเดือน → นับติดกัน 3 วัน', () {
    final stats = ReadingStats.from([
      _log(DateTime(2026, 11, 2, 8)),
      _log(DateTime(2026, 11, 1, 23)),
      _log(DateTime(2026, 10, 31, 9)),
      _log(DateTime(2026, 10, 29, 9)), // ขาดวันที่ 30 → ไม่นับ
    ], now: now);
    expect(stats.streakDays, 3);
  });

  test('วันนี้ยังไม่อ่าน แต่เมื่อวานอ่าน → streak ยังไม่ขาด', () {
    final stats = ReadingStats.from([
      _log(DateTime(2026, 11, 1, 10)),
      _log(DateTime(2026, 10, 31, 10)),
    ], now: now);
    expect(stats.streakDays, 2);
    expect(stats.todayMinutes, 0);
  });

  test('ไม่ได้อ่านมา 2 วัน → streak = 0', () {
    expect(
      ReadingStats.from([_log(DateTime(2026, 10, 31))], now: now).streakDays,
      0,
    );
  });

  test('เวลาวันนี้รวมเฉพาะวันนี้ / เฉลี่ยคิดเฉพาะบันทึกที่มีคะแนน', () {
    final stats = ReadingStats.from([
      _log(DateTime(2026, 11, 2, 9), minutes: 10, score: 90),
      _log(DateTime(2026, 11, 2, 12), minutes: 20),
      _log(DateTime(2026, 11, 1, 12), minutes: 7, score: 61),
    ], now: now);
    expect(stats.todayMinutes, 30);
    expect(stats.totalMinutes, 37);
    expect(stats.averageScore, 76);
    expect(stats.goalMet(30), isTrue);
    expect(stats.goalMet(31), isFalse);
  });

  test('ไม่มีบันทึกที่มีคะแนน → คะแนนเฉลี่ย null', () {
    expect(ReadingStats.from([], now: now).averageScore, isNull);
  });

  test('ระดับคะแนน: 80+ แม่น, 60+ ดี, ต่ำกว่านั้นควรทบทวน', () {
    expect(ScoreLevel.of(80), ScoreLevel.mastered);
    expect(ScoreLevel.of(79), ScoreLevel.good);
    expect(ScoreLevel.of(60), ScoreLevel.good);
    expect(ScoreLevel.of(59), ScoreLevel.review);
    expect(ScoreLevel.of(null), ScoreLevel.none);
  });
}
