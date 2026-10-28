import 'package:cloud_firestore/cloud_firestore.dart';

import 'article_tag.dart';
import 'content_language.dart';

/// 1 เอกสารใน collection `study_logs` = การอ่านและสรุป 1 ครั้ง
class StudyLog {
  const StudyLog({
    required this.id,
    required this.userId,
    required this.articleTitle,
    required this.articleUrl,
    required this.originalContent,
    required this.userSummary,
    required this.readingTimeMinutes,
    required this.tags,
    required this.language,
    required this.sourceId,
    required this.pageId,
    required this.aiScore,
    required this.aiFeedback,
    required this.createdAt,
    required this.updatedAt,
  });

  /// document ID ของ Firestore (ไม่ได้เก็บเป็น field ในเอกสาร)
  final String id;
  final String userId;
  final String articleTitle;
  final String articleUrl;
  final String originalContent;
  final String userSummary;
  final int readingTimeMinutes;

  /// แท็กไม่เกิน 3 อัน: id หมวดยอดฮิต (เช่น "history") หรือหัวข้อที่ค้นเอง
  final List<String> tags;
  final ContentLanguage language;

  /// แหล่งข้อมูลและ id ของบทความ ใช้กันการสุ่มเจอบทความที่อ่านแล้ว (บันทึกเก่าไม่มี pageId)
  final String sourceId;
  final int? pageId;

  /// null = ยังไม่ได้ให้ AI ประเมิน (เช่น ตอน AI ล่ม ผู้ใช้เลือกบันทึกไว้ก่อน)
  final int? aiScore;
  final String? aiFeedback;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isEvaluated => aiScore != null;

  /// รหัสบทความ (ตรงกับ Article.readKey) null = บันทึกเก่าที่ไม่ได้เก็บ pageId
  String? get readKey =>
      pageId == null ? null : '$sourceId:${language.code}:$pageId';

  /// แปลงเอกสารจาก Firestore เป็น object ของ Dart
  /// ใส่ค่า default ทุก field เพื่อกันแอปแครชถ้าเอกสารบางอันข้อมูลไม่ครบ
  factory StudyLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return StudyLog(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      articleTitle: data['articleTitle'] as String? ?? '—',
      articleUrl: data['articleUrl'] as String? ?? '',
      originalContent: data['originalContent'] as String? ?? '',
      userSummary: data['userSummary'] as String? ?? '',
      readingTimeMinutes: (data['readingTimeMinutes'] as num?)?.toInt() ?? 0,
      // บันทึกเก่าไม่มี tags แต่อาจมี category (หมวดเดียว) → แปลงเป็นแท็ก
      tags: ArticleTag.normalize(
        data['tags'] as List? ??
            [if (data['category'] != null) data['category']],
      ),
      // บันทึกเก่าก่อนมีหลายภาษาเป็นภาษาไทยทั้งหมด
      language: ContentLanguage.fromCode(
        data['language'] as String?,
        fallback: ContentLanguage.th,
      ),
      sourceId: data['source'] as String? ?? 'wikipedia',
      pageId: (data['pageId'] as num?)?.toInt(),
      aiScore: (data['aiScore'] as num?)?.toInt(),
      aiFeedback: data['aiFeedback'] as String?,
      // serverTimestamp จะเป็น null ชั่วขณะ ก่อนเซิร์ฟเวอร์ยืนยัน จึงใช้เวลาปัจจุบันแทน
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
