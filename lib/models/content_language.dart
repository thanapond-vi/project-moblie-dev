import 'dart:ui' show Locale;

/// ภาษาที่แอปรองรับ ใช้กับ 3 เรื่องแยกกันใน Settings:
/// ภาษาของแอป (UI + Feedback จาก AI), ภาษาที่สุ่มบทความ, และภาษาที่ TTS อ่าน
///
/// เรียง English ก่อน และแสดงเป็นชื่อภาษาสากลภาษาอังกฤษ (English / Chinese / Thai) ไม่ใช้ธง
enum ContentLanguage {
  en(
    code: 'en',
    label: 'English',
    ttsLocale: 'en-US',
    aiLanguage: 'English',
    minWikitextBytes: 15000,
    minContentChars: 3000,
  ),
  zh(
    code: 'zh',
    label: 'Chinese',
    ttsLocale: 'zh-CN',
    aiLanguage:
        'Simplified Chinese, but keep loanwords and technical terms that are '
        'normally written in English (for example AI, DNA, API) in English',
    // ภาษาจีน 1 ตัวอักษรเก็บความหมายได้มาก เกณฑ์จำนวนตัวอักษรจึงต่ำกว่า
    minWikitextBytes: 15000,
    minContentChars: 1200,
  ),
  th(
    code: 'th',
    label: 'Thai',
    ttsLocale: 'th-TH',
    aiLanguage:
        'Thai, but keep technical terms that Thai speakers commonly write in '
        'English (for example AI, DNA, algorithm, feedback) in English',
    // อักษรไทย 1 ตัว = 3 bytes ใน wikitext จึงต้องตั้งเกณฑ์ bytes สูงกว่าภาษาอังกฤษ
    minWikitextBytes: 20000,
    minContentChars: 2500,
  );

  const ContentLanguage({
    required this.code,
    required this.label,
    required this.ttsLocale,
    required this.aiLanguage,
    required this.minWikitextBytes,
    required this.minContentChars,
  });

  /// รหัสภาษา: subdomain ของ Wikipedia, locale ของแอป, ค่าที่เก็บใน Firestore / SharedPreferences
  final String code;

  /// ชื่อที่แสดงใน Settings (เป็นคำ ไม่มีไอคอน)
  final String label;

  /// locale ของเสียงอ่าน (flutter_tts)
  final String ttsLocale;

  /// คำอธิบายภาษาที่ใส่ใน prompt ให้ AI ตอบกลับ
  final String aiLanguage;

  /// ความยาวขั้นต่ำของบทความที่ถือว่า "ยาวพอให้อ่าน"
  final int minWikitextBytes;
  final int minContentChars;

  Locale get locale => Locale(code);

  String get wikiHost => '$code.wikipedia.org';

  /// Wikipedia ภาษาจีนเก็บทั้งตัวเต็มและตัวย่อปนกัน ต้องขอให้แปลงเป็นตัวย่อ (zh-cn)
  String? get wikiVariant => this == ContentLanguage.zh ? 'zh-cn' : null;

  /// แปลงรหัสที่เก็บไว้กลับเป็น enum (ค่าแปลก/ไม่มีค่า → fallback ซึ่งปกติคือ ENG)
  static ContentLanguage fromCode(
    String? code, {
    ContentLanguage fallback = ContentLanguage.en,
  }) => ContentLanguage.values.firstWhere(
    (l) => l.code == code,
    orElse: () => fallback,
  );
}
