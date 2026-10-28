import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../l10n/l10n.dart';
import 'settings_service.dart';
import 'slm_service.dart';

/// คำทักทายประจำวันบนหน้าแรก ให้ AI คิดใหม่ "วันละครั้ง" ต่อภาษา
///
/// - เก็บคำทักทายของวันนี้ไว้ใน SharedPreferences: เปิดแอปซ้ำในวันเดียวกันไม่ต้องเรียก AI อีก
///   (ประหยัดโควตา Groq และแสดงได้ทันที)
/// - ระหว่างรอ AI หรือ AI ล่ม → ใช้ข้อความสำรองจากไฟล์ภาษา (greetingFallback)
class GreetingService {
  GreetingService._();
  static final GreetingService instance = GreetingService._();

  static const _key = 'dailyGreeting';

  /// null = ยังไม่มี (หน้าจอแสดงข้อความสำรอง)
  final ValueNotifier<String?> text = ValueNotifier(null);

  final _slm = SlmService();
  String? _loadingFor;

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// เรียกตอนเข้าหน้าแรก และเมื่อเปลี่ยนภาษาแอป
  Future<void> load() async {
    final language = SettingsService.instance.appLanguage.value;
    final cacheId = '${_today()}|${language.code}';
    if (_loadingFor == cacheId) return; // กำลังโหลดชุดนี้อยู่แล้ว
    _loadingFor = cacheId;
    text.value = null;

    try {
      final prefs = await SettingsService.instance.prefs;
      // 1) วันนี้ + ภาษานี้ เคยให้ AI คิดไว้แล้ว → ใช้ของเดิม
      final raw = prefs.getString(_key);
      if (raw != null) {
        final cached = jsonDecode(raw) as Map<String, dynamic>;
        if (cached['id'] == cacheId) {
          text.value = cached['text'] as String?;
          return;
        }
      }
      // 2) ยังไม่มี → ให้ AI คิดใหม่ แล้วเก็บไว้ใช้ทั้งวัน
      final greeting = await _slm.dailyGreeting(
        language: language,
        date: DateTime.now(),
      );
      if (_loadingFor != cacheId) return; // ระหว่างรอ ผู้ใช้เปลี่ยนภาษาไปแล้ว
      text.value = greeting;
      await prefs.setString(
        _key,
        jsonEncode({'id': cacheId, 'text': greeting}),
      );
    } catch (_) {
      // AI ใช้ไม่ได้ → หน้าจอใช้ข้อความสำรอง ไม่ต้องแจ้ง error
      if (_loadingFor == cacheId) text.value = null;
    } finally {
      if (_loadingFor == cacheId) _loadingFor = null;
    }
  }

  /// ข้อความที่แสดงจริง: ของ AI ถ้ามี ไม่งั้นใช้ข้อความสำรองตามภาษาแอป
  static String display(String? fromAi, AppLocalizations l10n) =>
      fromAi ?? l10n.greetingFallback;
}
