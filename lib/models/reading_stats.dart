import 'study_log.dart';

/// สถิติสรุปจากประวัติการอ่านทั้งหมด (คำนวณในเครื่อง ไม่ต้องเก็บแยกใน Firestore)
class ReadingStats {
  const ReadingStats({
    required this.totalMinutes,
    required this.articles,
    required this.averageScore,
    required this.streakDays,
    required this.todayMinutes,
  });

  // StudyLog มาจาก lib/models/study_log.dart
  factory ReadingStats.from(List<StudyLog> logs, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    final scored = [
      for (final l in logs)
        if (l.aiScore != null) l.aiScore!,
    ];
    final days = {for (final l in logs) _day(l.createdAt)};
    return ReadingStats(
      totalMinutes: logs.fold(0, (sum, l) => sum + l.readingTimeMinutes),
      articles: logs.length,
      averageScore: scored.isEmpty
          ? null
          : (scored.reduce((a, b) => a + b) / scored.length).round(),
      streakDays: streakOf(days, today),
      todayMinutes: logs
          .where((l) => _day(l.createdAt) == today)
          .fold(0, (sum, l) => sum + l.readingTimeMinutes),
    );
  }

  final int totalMinutes;
  final int articles;

  /// null = ยังไม่มีบันทึกที่ได้คะแนน
  final int? averageScore;

  /// จำนวนวันติดกันที่อ่าน นับถอยจากวันนี้ (ถ้าวันนี้ยังไม่อ่าน นับจากเมื่อวาน ยังไม่ขาดจนกว่าจะหมดวัน)
  final int streakDays;
  final int todayMinutes;

  /// เป้าหมายรายวัน = อ่านครบ 1 รอบตามเวลาที่ตั้งไว้
  bool goalMet(int goalMinutes) => todayMinutes >= goalMinutes;

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  static int streakOf(Set<DateTime> days, DateTime today) {
    var day = days.contains(today)
        ? today
        : DateTime(today.year, today.month, today.day - 1);
    var count = 0;
    while (days.contains(day)) {
      count++;
      // สร้างวันใหม่จากปี/เดือน/วัน (ไม่ลบ 24 ชม.) จะได้ไม่เพี้ยนช่วงปรับเวลา
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }
}
