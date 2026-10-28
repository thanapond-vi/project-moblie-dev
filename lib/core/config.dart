import 'package:flutter_dotenv/flutter_dotenv.dart';

/// รวมค่าตั้งค่าที่อ่านจากไฟล์ .env ไว้ที่เดียว
/// โค้ดส่วนอื่นเรียกผ่าน AppConfig เท่านั้น ไม่ต้องรู้ว่าค่ามาจากไหน
class AppConfig {
  AppConfig._();

  static String _get(String key, String fallback) {
    // ถ้าโหลด .env ไม่สำเร็จ dotenv จะยังไม่ initialize จึงต้องกันไว้
    if (!dotenv.isInitialized) return fallback;
    final value = dotenv.env[key]?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  static String get groqApiKey => _get('GROQ_API_KEY', '');
  static String get groqBaseUrl =>
      _get('GROQ_BASE_URL', 'https://api.groq.com/openai/v1');
  static String get groqModel => _get('GROQ_MODEL', 'qwen/qwen3.8-27b');
}
