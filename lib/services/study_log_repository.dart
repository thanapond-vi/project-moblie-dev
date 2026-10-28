import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../models/study_log.dart';
import '../l10n/l10n.dart';

/// CRUD ของ collection `study_logs` ใน Cloud Firestore
class StudyLogRepository {
  StudyLogRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _timeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _logs =>
      _db.collection('study_logs');

  // ---------- Read (realtime) ----------

  /// ดึงเฉพาะ log ของผู้ใช้คนนี้ แล้วเรียงใหม่สุดก่อน
  ///
  /// เรียงลำดับฝั่งแอปแทน `.orderBy('createdAt')` เพราะการใช้ where + orderBy
  /// คนละ field ต้องสร้าง Composite Index ใน Firestore ก่อน ข้อมูลของผู้ใช้ 1 คน
  /// มีไม่มาก การเรียงในแอปจึงเร็วพอและไม่ต้องตั้งค่าเพิ่ม
  Stream<List<StudyLog>> watchLogs(String userId) {
    return _logs.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      final logs = snapshot.docs.map(StudyLog.fromFirestore).toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return logs;
    });
  }

  // ---------- Create ----------

  /// สร้าง document ID ใหม่ในเครื่อง (ยังไม่ได้เขียนอะไรลงฐานข้อมูล)
  ///
  /// หน้าสรุปจองไว้ก่อนบันทึก ถ้าบันทึกครั้งแรก timeout แล้วกดซ้ำ จะเขียนทับ
  /// เอกสาร ID เดิม ไม่เกิดเอกสารซ้ำ 2 ชิ้น (ต่างจาก add() ที่สร้าง ID ใหม่ทุกครั้ง)
  String newLogId() => _logs.doc().id;

  Future<void> create({
    required String logId,
    required String userId,
    required String articleTitle,
    required String articleUrl,
    required String originalContent,
    required String userSummary,
    required int readingTimeMinutes,
    required List<String> tags,
    required String language,
    required String source,
    required int pageId,
    int? aiScore,
    String? aiFeedback,
  }) {
    return _run(
      () => _logs.doc(logId).set({
        'userId': userId,
        'articleTitle': articleTitle,
        'articleUrl': articleUrl,
        'originalContent': originalContent,
        'userSummary': userSummary,
        'readingTimeMinutes': readingTimeMinutes,
        'tags': tags, // ไม่เกิน 3 แท็ก เช่น ["history", "กาแฟ"]
        'language': language, // "en" | "zh" | "th"
        'source': source, // แหล่งข้อมูล เช่น "wikipedia"
        'pageId': pageId, // id บทความในแหล่งข้อมูล ใช้กันสุ่มซ้ำ
        'aiScore': aiScore,
        'aiFeedback': aiFeedback,
        // ใช้เวลาของเซิร์ฟเวอร์ ไม่ใช่เวลาเครื่อง เพื่อให้ทุกเครื่องเรียงตรงกัน
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  // ---------- Update ----------

  /// แก้ไขเฉพาะส่วนที่ผู้ใช้เปลี่ยนได้ (คำสรุป แท็ก ผลประเมิน) ไม่แตะ createdAt / originalContent / articleTitle
  Future<void> update({
    required String logId,
    required String userSummary,
    required List<String> tags,
    int? aiScore,
    String? aiFeedback,
  }) {
    return _run(
      () => _logs.doc(logId).update({
        'userSummary': userSummary,
        'tags': tags,
        'aiScore': aiScore,
        'aiFeedback': aiFeedback,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  // ---------- Delete ----------

  Future<void> delete(String logId) => _run(() => _logs.doc(logId).delete());

  /// ครอบทุกคำสั่ง: timeout + แปลง FirebaseException เป็นข้อความตามภาษาแอป
  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw AppException(tr.errPermissionDenied);
      }
      if (e.code == 'unavailable') {
        throw AppException(tr.errDbUnavailable);
      }
      throw AppException(tr.errSaveFailed(e.code));
    } on TimeoutException {
      throw AppException(tr.errDbTimeout);
    }
  }
}
