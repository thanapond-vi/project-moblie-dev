import 'study_log.dart';

/// ผู้ใช้ให้คะแนนตัวเองหลังเฉลย
enum ReviewRating {
  /// ลืม → กลับไปกล่อง 1
  again,

  /// ยาก → อยู่กล่องเดิม
  hard,

  /// ดี → ขึ้น 1 กล่อง
  good,

  /// ง่าย → ขึ้น 2 กล่อง
  easy;

  /// นับเป็น "จำได้" (ใช้คิดอัตราทบทวนสำเร็จ)
  bool get passed => this == good || this == easy;
}

/// การทบทวนแบบกล่องเลื่อนขั้น (Leitner system)
///
/// มี 5 กล่อง แต่ละกล่องเว้นระยะต่างกัน (1 / 3 / 7 / 14 / 30 วัน)
/// จำได้ = เลื่อนไปกล่องที่เว้นนานขึ้น, ลืม = กลับกล่องแรก
/// บทความที่เพิ่งอ่านถึงรอบทบทวนครั้งแรกวันถัดไป
abstract final class ReviewSchedule {
  static const intervals = [1, 3, 7, 14, 30];
  static int get boxes => intervals.length;

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  // StudyLog มาจาก lib/models/study_log.dart
  /// วันที่ถึงรอบทบทวน (ระดับวัน ไม่สนเวลา)
  static DateTime dueDay(StudyLog log) {
    final next = log.nextReviewAt;
    if (next != null) return _day(next);
    final read = _day(log.createdAt);
    return DateTime(read.year, read.month, read.day + intervals.first);
  }

  static bool isDue(StudyLog log, DateTime now) =>
      !dueDay(log).isAfter(_day(now));

  /// เลยกำหนดมากี่วัน (0 = ครบกำหนดวันนี้, ติดลบ = ยังไม่ถึง)
  static int overdueDays(StudyLog log, DateTime now) =>
      _day(now).difference(dueDay(log)).inDays;

  /// กล่องถัดไปตามคะแนนที่ให้ (1–5)
  static int nextBox(int box, ReviewRating rating) {
    final current = box < 1 ? 1 : box;
    final next = switch (rating) {
      ReviewRating.again => 1,
      ReviewRating.hard => current,
      ReviewRating.good => current + 1,
      ReviewRating.easy => current + 2,
    };
    // ยังไม่เคยทบทวนแล้วตอบ "ยาก" = กล่อง 1 (ไม่ใช่ 0)
    return next.clamp(1, boxes);
  }

  /// จำนวนวันจนถึงรอบถัดไปของกล่องนั้น
  static int intervalOf(int box) => intervals[box.clamp(1, boxes) - 1];

  /// วันที่ครบกำหนดครั้งถัดไป หลังทบทวนวันนี้แล้วได้กล่อง [box]
  static DateTime nextDue(int box, DateTime now) {
    final today = _day(now);
    return DateTime(today.year, today.month, today.day + intervalOf(box));
  }

  /// เรียงสิ่งที่ต้องทบทวน: เลยกำหนดนานสุดก่อน แล้วกล่องต่ำ (ใกล้ลืม) ก่อน
  static List<StudyLog> dueList(List<StudyLog> logs, DateTime now) =>
      [
        for (final l in logs)
          if (isDue(l, now)) l,
      ]..sort((a, b) {
        final byOverdue = overdueDays(b, now).compareTo(overdueDays(a, now));
        return byOverdue != 0 ? byOverdue : a.reviewBox.compareTo(b.reviewBox);
      });

  /// ยังไม่ถึงกำหนด เรียงตามวันที่ใกล้สุดก่อน
  static List<StudyLog> upcoming(List<StudyLog> logs, DateTime now) => [
    for (final l in logs)
      if (!isDue(l, now)) l,
  ]..sort((a, b) => dueDay(a).compareTo(dueDay(b)));

  /// จำนวนบทความในแต่ละกล่อง (index 0 = กล่อง 1) ยังไม่เคยทบทวนนับรวมกล่อง 1
  static List<int> boxCounts(List<StudyLog> logs) {
    final counts = List.filled(boxes, 0);
    for (final l in logs) {
      counts[(l.reviewBox < 1 ? 1 : l.reviewBox).clamp(1, boxes) - 1]++;
    }
    return counts;
  }

  /// อัตราทบทวนสำเร็จ 0–100 (null = ยังไม่เคยทบทวน)
  static int? successRate(List<StudyLog> logs) {
    final total = logs.fold(0, (sum, l) => sum + l.reviewsTotal);
    if (total == 0) return null;
    final passed = logs.fold(0, (sum, l) => sum + l.reviewsPassed);
    return (passed / total * 100).round();
  }
}
