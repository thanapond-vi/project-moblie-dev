import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_exception.dart';
import '../l10n/l10n.dart';
import 'auth_service.dart';
import 'bookmark_service.dart';
import 'profile_service.dart';
import 'session_service.dart';

/// ลบบัญชีถาวร: ข้อมูลของผู้ใช้ทั้งหมดใน Firestore + ในเครื่อง แล้วจึงลบบัญชี Firebase Auth
///
/// ลำดับ (หยุดทันทีถ้าขั้นไหนพลาด ข้อมูลที่ยังไม่ถึงคิวจะยังอยู่ครบ):
/// 1. ยืนยันตัวตน: รหัสผ่าน หรือเข้าสู่ระบบ Google อีกครั้ง (ผิด/ยกเลิก = ยังไม่มีอะไรถูกลบ)
/// 2. โปรไฟล์ users/{uid} (ถ้ากฎ Firestore ยังไม่อนุญาต จะหยุดตรงนี้ ประวัติยังอยู่)
/// 3. ประวัติการอ่านทั้งหมดใน study_logs
/// 4. บัญชี Firebase Auth
/// 5. ข้อมูลในเครื่องของบัญชีนี้ (เรื่องที่อ่านค้าง, บุ๊กมาร์ก, cache โปรไฟล์)
class AccountService {
  AccountService({
    // AuthService มาจาก lib/services/auth_service.dart
    AuthService? auth,
    Future<void> Function(String uid)? deleteRemoteData,
    Future<void> Function(String uid)? clearLocalData,
    String? Function()? currentUid,
  }) : _auth = auth ?? AuthService(),
       _deleteRemoteData = deleteRemoteData ?? _deleteFirestore,
       _clearLocalData = clearLocalData ?? _clearDevice,
       _currentUid =
           currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final AuthService _auth;
  final Future<void> Function(String uid) _deleteRemoteData;
  final Future<void> Function(String uid) _clearLocalData;
  final String? Function() _currentUid;

  static const _timeout = Duration(seconds: 30);

  /// Firestore ให้ batch ละไม่เกิน 500 คำสั่ง
  static const _batchSize = 400;

  /// คืน false ถ้าผู้ใช้ยกเลิกหน้าต่างยืนยันตัวตนของ Google (ยังไม่มีอะไรถูกลบ)
  /// [password] = null สำหรับบัญชีที่ล็อกอินด้วย Google
  Future<bool> deleteAccount({String? password}) async {
    final uid = _currentUid();
    // context.l10n มาจาก lib/l10n/l10n.dart
    // AppException มาจาก lib/core/app_exception.dart
    if (uid == null) throw AppException(tr.errLoginAgain);
    if (!await _auth.reauthenticate(password: password)) return false;
    await _deleteRemoteData(uid);
    await _auth.deleteCurrentUser();
    await _clearLocalData(uid);
    return true;
  }

  static Future<void> _deleteFirestore(String uid) async {
    final db = FirebaseFirestore.instance;
    try {
      // โปรไฟล์ก่อน: ถ้ากฎยังไม่อนุญาตจะพลาดตรงนี้ ก่อนประวัติการอ่านจะถูกลบ
      await db.collection('users').doc(uid).delete().timeout(_timeout);
      while (true) {
        final page = await db
            .collection('study_logs')
            .where('userId', isEqualTo: uid)
            .limit(_batchSize)
            .get()
            .timeout(_timeout);
        if (page.docs.isEmpty) break;
        final batch = db.batch();
        for (final doc in page.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit().timeout(_timeout);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw AppException(tr.errPermissionDenied);
      }
      if (e.code == 'unavailable') throw AppException(tr.errDbUnavailable);
      throw AppException(tr.errSaveFailed(e.code));
    } on TimeoutException {
      throw AppException(tr.errDbTimeout);
    }
  }

  /// ลบ key ของบัญชีนี้ในเครื่อง (ค่าตั้งค่าของเครื่อง เช่น ภาษา/ธีม เก็บไว้ตามเดิม)
  static Future<void> _clearDevice(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'activeSession_$uid',
        'bookmarks_$uid',
        'profile_$uid',
      ]) {
        await prefs.remove(key);
      }
    } catch (_) {
      // บัญชีถูกลบไปแล้ว ข้อมูลในเครื่องที่ลบไม่ได้ไม่มีใครเข้าถึงด้วย uid นี้อีก
    }
    // SessionService มาจาก lib/services/session_service.dart
    SessionService.instance.detach();
    // ProfileService มาจาก lib/services/profile_service.dart
    ProfileService.instance.detach();
    // BookmarkService มาจาก lib/services/bookmark_service.dart
    BookmarkService.instance.clear();
  }
}
