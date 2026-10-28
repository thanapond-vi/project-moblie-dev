import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/reading_session.dart';
import 'settings_service.dart';

/// เก็บ "การอ่านที่ค้างอยู่" ลง SharedPreferences เพื่อให้ปิดแอปแล้วเปิดใหม่ก็ยังอ่านต่อได้
///
/// - เก็บเป็น JSON 1 ก้อน ใต้ key `activeSession_<uid>` แยกตามผู้ใช้
///   (ถ้าสลับบัญชีในเครื่องเดียวกัน จะไม่เห็นเซสชันของคนอื่น)
/// - `current` เป็น ValueNotifier: หน้า Home ฟังค่านี้เพื่อแสดงการ์ด "กำลังอ่านค้างอยู่"
///   และล็อกปุ่มสุ่มบทความใหม่
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  final ValueNotifier<ReadingSession?> current = ValueNotifier(null);
  String? _uid;

  String get _key => 'activeSession_$_uid';

  /// โหลดเซสชันของผู้ใช้คนนี้ (เรียกตอนเข้าหน้า Home)
  Future<void> load(String uid) async {
    _uid = uid;
    try {
      final prefs = await SettingsService.instance.prefs;
      final raw = prefs.getString(_key);
      current.value = raw == null
          ? null
          : ReadingSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // ข้อมูลเสีย (เช่น เปลี่ยนโครงสร้าง JSON) ก็ทิ้งไป เริ่มใหม่ได้ ไม่ให้แอปแครช
      current.value = null;
    }
  }

  Future<void> save(ReadingSession session) async {
    current.value = session;
    if (_uid == null) return;
    try {
      final prefs = await SettingsService.instance.prefs;
      await prefs.setString(_key, jsonEncode(session.toJson()));
    } catch (_) {
      // บันทึกลงเครื่องไม่ได้ ยังใช้งานต่อได้ในรอบนี้ (แค่ปิดแอปแล้วจะหาย)
    }
  }

  /// ล้างเซสชัน: เมื่อบันทึกสรุปสำเร็จ หรือผู้ใช้กดทิ้ง
  Future<void> clear() async {
    current.value = null;
    if (_uid == null) return;
    try {
      final prefs = await SettingsService.instance.prefs;
      await prefs.remove(_key);
    } catch (_) {}
  }

  /// ตอน Logout: ลืมผู้ใช้ปัจจุบัน (ข้อมูลยังอยู่ในเครื่อง ล็อกอินกลับมาก็อ่านต่อได้)
  void detach() {
    _uid = null;
    current.value = null;
  }
}
