import 'key_point.dart';

/// ผลการประเมินจาก AI
class AiEvaluation {
  const AiEvaluation({
    required this.score,
    required this.feedback,
    required this.model,
    required this.tags,
    this.keyPoints = const [],
    this.accuracyIssues = const [],
  });

  /// คะแนนความเข้าใจ 0–100
  final int score;
  final String feedback;

  /// ชื่อโมเดลที่ Groq ตอบกลับมาใน response เช่น "qwen/qwen3.8-27b" (ไว้แสดงตอนสาธิต)
  final String model;

  /// แท็กที่ AI แนะนำ (id หมวดยอดฮิต ไม่เกิน 3) ผู้ใช้แก้ต่อได้ก่อนบันทึก
  final List<String> tags;

  // KeyPoint มาจาก lib/models/key_point.dart
  /// ประเด็นสำคัญของบทความ พร้อมผลว่าคำสรุปครอบคลุมหรือยัง (ว่าง = โมเดลไม่ได้ส่งมา)
  final List<KeyPoint> keyPoints;

  /// สิ่งที่คำสรุปเขียนขัดกับบทความ
  final List<String> accuracyIssues;
}
