import 'study_log.dart';

/// ช่วงเวลาที่เลือกดูในแท็บสถิติ
enum StatsRange {
  week(7),
  month(30),

  /// ทั้งหมด: ไม่มีช่วงก่อนหน้าให้เทียบ และกราฟเวลาอ่านรวมเป็นรายสัปดาห์
  all(null);

  const StatsRange(this.days);

  /// จำนวนวันในช่วง (null = ตั้งแต่บันทึกแรก)
  final int? days;
}

/// แท่ง 1 แท่งในกราฟเวลาอ่าน (1 วัน หรือ 1 สัปดาห์)
class MinutesBucket {
  const MinutesBucket(this.start, this.minutes);

  final DateTime start;
  final int minutes;
}

/// คะแนน 1 จุดในกราฟคะแนนตามเวลา
class ScorePoint {
  const ScorePoint(this.at, this.score, this.title);

  final DateTime at;
  final int score;
  final String title;
}

/// หมวด 1 แถวในกราฟหมวดที่อ่าน
class TopicCount {
  const TopicCount(this.tag, this.count, this.averageScore);

  /// id แท็ก (null = รวมหมวดที่เหลือเป็น "อื่นๆ")
  final String? tag;
  final int count;

  /// null = ยังไม่มีบันทึกที่ได้คะแนนในหมวดนี้
  final int? averageScore;
}

/// สถิติของช่วงเวลาที่เลือก คำนวณจากประวัติการอ่านในเครื่อง (ไม่ต้องเก็บแยกใน Firestore)
class PeriodStats {
  const PeriodStats({
    required this.range,
    required this.minutes,
    required this.articles,
    required this.averageScore,
    required this.previousMinutes,
    required this.previousArticles,
    required this.previousAverageScore,
    required this.buckets,
    required this.weekly,
    required this.scores,
    required this.topics,
  });

  /// ปฏิทินย้อนหลัง 12 สัปดาห์ (ไม่ขึ้นกับช่วงที่เลือก)
  static const calendarWeeks = 12;

  /// แสดงหมวดได้สูงสุดเท่านี้ ที่เหลือรวมเป็น "อื่นๆ"
  static const maxTopics = 5;

  factory PeriodStats.from(
    // StudyLog มาจาก lib/models/study_log.dart
    List<StudyLog> logs,
    StatsRange range, {
    DateTime? now,
  }) {
    final today = day(now ?? DateTime.now());
    final days = range.days;

    // ช่วงนี้ = [start, พรุ่งนี้) ช่วงก่อนหน้า = [start - days, start)
    final DateTime start;
    if (days != null) {
      start = DateTime(today.year, today.month, today.day - days + 1);
    } else {
      final first = logs.isEmpty
          ? today
          : logs
                .map((l) => day(l.createdAt))
                .reduce((a, b) => a.isBefore(b) ? a : b);
      start = first;
    }
    final end = DateTime(today.year, today.month, today.day + 1);
    final inRange = [
      for (final l in logs)
        if (!l.createdAt.isBefore(start) && l.createdAt.isBefore(end)) l,
    ];
    final previous = days == null
        ? null
        : [
            for (final l in logs)
              if (!l.createdAt.isBefore(
                    DateTime(start.year, start.month, start.day - days),
                  ) &&
                  l.createdAt.isBefore(start))
                l,
          ];

    // ทั้งหมด + เกิน 60 วัน → รวมเป็นรายสัปดาห์ (แท่งรายวันจะบางจนอ่านไม่ออก)
    final spanDays = end.difference(start).inDays;
    final weekly = days == null && spanDays > 60;
    final buckets = <MinutesBucket>[];
    if (weekly) {
      var cursor = weekStart(start);
      while (cursor.isBefore(end)) {
        final next = DateTime(cursor.year, cursor.month, cursor.day + 7);
        buckets.add(
          MinutesBucket(cursor, _minutesBetween(inRange, cursor, next)),
        );
        cursor = next;
      }
    } else {
      for (var i = 0; i < spanDays; i++) {
        final d = DateTime(start.year, start.month, start.day + i);
        final next = DateTime(d.year, d.month, d.day + 1);
        buckets.add(MinutesBucket(d, _minutesBetween(inRange, d, next)));
      }
    }

    final scores = [
      for (final l in inRange)
        if (l.aiScore != null)
          ScorePoint(l.createdAt, l.aiScore!, l.articleTitle),
    ]..sort((a, b) => a.at.compareTo(b.at));

    return PeriodStats(
      range: range,
      minutes: _minutes(inRange),
      articles: inRange.length,
      averageScore: _average(inRange),
      previousMinutes: previous == null ? null : _minutes(previous),
      previousArticles: previous?.length,
      previousAverageScore: previous == null ? null : _average(previous),
      buckets: buckets,
      weekly: weekly,
      scores: scores,
      topics: _topics(inRange),
    );
  }

  final StatsRange range;
  final int minutes;
  final int articles;
  final int? averageScore;

  /// ค่าของช่วงก่อนหน้าที่ยาวเท่ากัน (null = ไม่มีให้เทียบ เช่น ช่วง "ทั้งหมด")
  final int? previousMinutes;
  final int? previousArticles;
  final int? previousAverageScore;

  final List<MinutesBucket> buckets;

  /// true = แต่ละแท่งคือ 1 สัปดาห์ (ไม่ใช่ 1 วัน)
  final bool weekly;
  final List<ScorePoint> scores;
  final List<TopicCount> topics;

  bool get isEmpty => articles == 0;

  static DateTime day(DateTime t) => DateTime(t.year, t.month, t.day);

  /// วันจันทร์ของสัปดาห์นั้น
  static DateTime weekStart(DateTime t) =>
      DateTime(t.year, t.month, t.day - (t.weekday - DateTime.monday));

  static int _minutes(List<StudyLog> logs) =>
      logs.fold(0, (sum, l) => sum + l.readingTimeMinutes);

  static int _minutesBetween(List<StudyLog> logs, DateTime from, DateTime to) =>
      _minutes([
        for (final l in logs)
          if (!l.createdAt.isBefore(from) && l.createdAt.isBefore(to)) l,
      ]);

  static int? _average(List<StudyLog> logs) {
    final scored = [
      for (final l in logs)
        if (l.aiScore != null) l.aiScore!,
    ];
    if (scored.isEmpty) return null;
    return (scored.reduce((a, b) => a + b) / scored.length).round();
  }

  /// นับบทความต่อแท็ก (บทความเดียวมีได้หลายแท็ก) เรียงจากมากไปน้อย
  static List<TopicCount> _topics(List<StudyLog> logs) {
    final byTag = <String, List<StudyLog>>{};
    for (final l in logs) {
      for (final tag in l.tags) {
        byTag.putIfAbsent(tag, () => []).add(l);
      }
    }
    final sorted = byTag.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final top = [
      for (final e in sorted.take(maxTopics))
        TopicCount(e.key, e.value.length, _average(e.value)),
    ];
    final rest = sorted.skip(maxTopics).expand((e) => e.value).toSet().toList();
    if (rest.isNotEmpty) top.add(TopicCount(null, rest.length, _average(rest)));
    return top;
  }

  /// นาทีที่อ่านในแต่ละวันย้อนหลัง [calendarWeeks] สัปดาห์ (เริ่มวันจันทร์) ใช้กับปฏิทิน
  static Map<DateTime, int> calendar(List<StudyLog> logs, {DateTime? now}) {
    final today = day(now ?? DateTime.now());
    final first = weekStart(
      DateTime(today.year, today.month, today.day - (calendarWeeks - 1) * 7),
    );
    final result = <DateTime, int>{};
    for (final l in logs) {
      final d = day(l.createdAt);
      if (d.isBefore(first) || d.isAfter(today)) continue;
      result[d] = (result[d] ?? 0) + l.readingTimeMinutes;
    }
    return result;
  }

  /// จำนวนวันติดกันที่ยาวที่สุดตลอดประวัติ
  static int longestStreak(List<StudyLog> logs) {
    final days = {for (final l in logs) day(l.createdAt)}.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final d in days) {
      final expected = prev == null
          ? null
          : DateTime(prev.year, prev.month, prev.day + 1);
      run = d == expected ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }
}
