import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_language.dart';

/// ภาษา 3 ค่าที่รอใช้หลังรีสตาร์ต
typedef PendingLanguages = ({
  ContentLanguage app,
  ContentLanguage article,
  ContentLanguage? tts,
});

/// ค่าตั้งค่าที่เก็บในเครื่อง (SharedPreferences)
///
/// ภาษาแยกเป็น 3 ค่าที่ตั้งได้อิสระ:
/// - appLanguage:     ภาษาของแอป (เมนู ข้อความ และ Feedback/คำทักทายจาก AI)
/// - articleLanguage: ภาษาที่สุ่มบทความ (subdomain ของ Wikipedia)
/// - ttsLanguage:     ภาษาที่ TTS อ่าน (null = AUTO อ่านตามภาษาของบทความ)
///
/// ใช้ ValueNotifier เพื่อให้ widget ที่ฟังอยู่ rebuild เองเมื่อค่าเปลี่ยน
/// สร้างเป็น singleton เพราะทั้งแอปต้องใช้ค่าชุดเดียวกัน
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _keyTimer = 'defaultTimerMinutes';
  static const _keyDark = 'isDarkMode';
  static const _keyAppLanguage = 'appLanguage';
  // ชื่อ key เดิมจากรุ่นก่อน (ตอนที่มีภาษาเดียว) ผู้ใช้เก่าจึงไม่เสียค่าที่ตั้งไว้
  static const _keyArticleLanguage = 'contentLanguage';
  static const _keyTtsLanguage = 'ttsLanguage';
  static const _keyTtsRate = 'ttsRate';
  static const _keySource = 'articleSource';

  static const List<int> timerOptions = [15, 30, 45];
  static const int defaultTimer = 30;

  /// ตัวคูณความเร็วเสียงอ่านที่ให้เลือก (1.0 = ความเร็วปกติ)
  static const List<double> ttsRateOptions = [0.75, 1.0, 1.25, 1.5];

  /// ค่าเริ่มต้นของผู้ใช้ใหม่ = ENG ทั้ง 3 ภาษา
  static const ContentLanguage defaultLanguage = ContentLanguage.en;

  /// ค่าที่เก็บแทน "AUTO" ของภาษา TTS
  static const _ttsAuto = 'auto';

  SharedPreferences? _prefs;

  final ValueNotifier<int> timerMinutes = ValueNotifier(defaultTimer);
  final ValueNotifier<bool> isDarkMode = ValueNotifier(false);
  final ValueNotifier<ContentLanguage> appLanguage = ValueNotifier(
    defaultLanguage,
  );
  final ValueNotifier<ContentLanguage> articleLanguage = ValueNotifier(
    defaultLanguage,
  );

  /// null = AUTO (อ่านด้วยเสียงภาษาเดียวกับบทความ)
  final ValueNotifier<ContentLanguage?> ttsLanguage = ValueNotifier(
    defaultLanguage,
  );
  final ValueNotifier<double> ttsRate = ValueNotifier(1.0);

  /// ภาษาที่บันทึกไว้แล้วแต่ยังไม่ได้ใช้ (ผู้ใช้เลือก "ไว้ทีหลัง" ตอนถามรีสตาร์ต)
  /// null = ไม่มีค่าค้าง; จะถูกใช้จริงตอนเปิดแอปครั้งถัดไป
  final ValueNotifier<PendingLanguages?> pendingLanguages = ValueNotifier(null);

  /// แหล่งข้อมูลบทความที่เลือก (ดู ArticleSources)
  final ValueNotifier<String> sourceId = ValueNotifier('wikipedia');

  /// เรียกใน main() ก่อน runApp เพื่อให้ธีมและภาษาถูกต้องตั้งแต่หน้าแรก
  Future<void> load() async {
    try {
      final prefs = _prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_keyTimer) ?? defaultTimer;
      timerMinutes.value = timerOptions.contains(saved) ? saved : defaultTimer;
      isDarkMode.value = prefs.getBool(_keyDark) ?? false;
      appLanguage.value = ContentLanguage.fromCode(
        prefs.getString(_keyAppLanguage),
      );
      articleLanguage.value = ContentLanguage.fromCode(
        prefs.getString(_keyArticleLanguage),
      );
      final tts = prefs.getString(_keyTtsLanguage);
      final isNewUser = prefs.getString(_keyArticleLanguage) == null;
      // ผู้ใช้ใหม่ = ENG / ผู้ใช้รุ่นเก่าที่ไม่เคยตั้งภาษา TTS = AUTO (อ่านตามภาษาบทความเดิมของเขา)
      ttsLanguage.value = tts == _ttsAuto || (tts == null && !isNewUser)
          ? null
          : ContentLanguage.fromCode(tts);
      final rate = prefs.getDouble(_keyTtsRate) ?? 1.0;
      ttsRate.value = ttsRateOptions.contains(rate) ? rate : 1.0;
      sourceId.value = prefs.getString(_keySource) ?? 'wikipedia';
    } catch (_) {
      // อ่านค่าไม่ได้ก็ใช้ค่า default ต่อ แอปยังทำงานได้
    }
  }

  Future<void> setTimerMinutes(int minutes) async {
    timerMinutes.value = minutes;
    await _prefs?.setInt(_keyTimer, minutes);
  }

  Future<void> setDarkMode(bool value) async {
    isDarkMode.value = value;
    await _prefs?.setBool(_keyDark, value);
  }

  /// ตั้งค่าภาษาทั้ง 3 ค่าพร้อมกัน (จากปุ่ม "ยืนยันภาษา" ใน Settings / หน้าตั้งค่าเริ่มต้น)
  ///
  /// บันทึกลงเครื่องเสมอ แต่จะ "ใช้ทันที" ก็ต่อเมื่อ [applyNow] = true (ผู้ใช้ยอมรีสตาร์ตแอป)
  /// ถ้าไม่ยอม แอปใช้ภาษาเดิมต่อไป แล้วค่าใหม่จะถูกโหลดตอนเปิดแอปครั้งถัดไป (ใน [load])
  Future<void> saveLanguages({
    required ContentLanguage app,
    required ContentLanguage article,
    required ContentLanguage? tts, // null = AUTO
    required bool applyNow,
  }) async {
    final prefs = await this.prefs;
    await prefs.setString(_keyAppLanguage, app.code);
    await prefs.setString(_keyArticleLanguage, article.code);
    await prefs.setString(_keyTtsLanguage, tts?.code ?? _ttsAuto);
    if (applyNow) {
      appLanguage.value = app; // MaterialApp ฟังค่านี้ → ข้อความทั้งแอปเปลี่ยน
      articleLanguage.value = article;
      ttsLanguage.value = tts;
      pendingLanguages.value = null;
    } else {
      pendingLanguages.value = (app: app, article: article, tts: tts);
    }
  }

  Future<void> setTtsRate(double value) async {
    ttsRate.value = value;
    await _prefs?.setDouble(_keyTtsRate, value);
  }

  Future<void> setSource(String id) async {
    sourceId.value = id;
    await _prefs?.setString(_keySource, id);
  }

  /// SharedPreferences ตัวเดียวกับที่โหลดไว้ (ให้ service อื่นใช้ร่วม)
  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();
}
