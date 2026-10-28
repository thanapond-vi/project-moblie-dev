import 'article.dart';

/// ขั้นตอนของเซสชันที่ค้างอยู่
enum SessionStage {
  /// กำลังอ่าน (พักไว้ได้ เวลานับต่อจากเดิม)
  reading,

  /// อ่านจบแล้ว กำลังเขียนสรุป (อ่านต่อ = ไปหน้าสรุป ไม่กลับไปดูบทความ เพื่อรักษาหลัก Active Recall)
  summarizing,
}

/// การอ่าน 1 รอบที่ยังไม่ได้บันทึกสรุป (เก็บใน SharedPreferences เป็น JSON)
///
/// มีได้ทีละ 1 เซสชันต่อผู้ใช้: ระหว่างที่มีเซสชันค้าง แอปจะไม่ให้สุ่มบทความใหม่
class ReadingSession {
  const ReadingSession({
    required this.article,
    required this.limitSeconds,
    required this.elapsedSeconds,
    required this.stage,
    required this.draftSummary,
    required this.updatedAt,
  });

  final Article article;

  /// เวลาอ่านที่ตั้งไว้ตอนเริ่ม (เปลี่ยนค่าตั้งค่าทีหลังก็ไม่กระทบรอบนี้)
  final int limitSeconds;

  /// เวลาที่อ่านไปแล้ว (วินาที)
  final int elapsedSeconds;
  final SessionStage stage;

  /// ร่างคำสรุปที่พิมพ์ไว้แล้วแต่ยังไม่ได้บันทึก
  final String draftSummary;
  final DateTime updatedAt;

  int get remainingSeconds =>
      (limitSeconds - elapsedSeconds).clamp(0, limitSeconds);

  /// เวลาอ่านจริงเป็นนาที (ปัดขึ้น อย่างน้อย 1 นาที) ใช้บันทึกลง Firestore
  int get readingMinutes => (elapsedSeconds / 60).ceil().clamp(1, 999);

  ReadingSession copyWith({
    int? elapsedSeconds,
    SessionStage? stage,
    String? draftSummary,
  }) => ReadingSession(
    article: article,
    limitSeconds: limitSeconds,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    stage: stage ?? this.stage,
    draftSummary: draftSummary ?? this.draftSummary,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'article': article.toJson(),
    'limitSeconds': limitSeconds,
    'elapsedSeconds': elapsedSeconds,
    'stage': stage.name,
    'draftSummary': draftSummary,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ReadingSession.fromJson(Map<String, dynamic> json) => ReadingSession(
    article: Article.fromJson(json['article'] as Map<String, dynamic>),
    limitSeconds: (json['limitSeconds'] as num).toInt(),
    elapsedSeconds: (json['elapsedSeconds'] as num).toInt(),
    stage: SessionStage.values.byName(json['stage'] as String),
    draftSummary: json['draftSummary'] as String? ?? '',
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}
