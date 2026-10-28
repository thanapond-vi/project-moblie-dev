import 'article_tag.dart';

/// หมวดที่ผู้ใช้เลือกก่อนสุ่มบทความ มี 3 แบบ:
/// - สุ่มทุกหมวด (any)
/// - หมวดยอดฮิต 1 ใน 5 (preset)
/// - หัวข้อที่พิมพ์ค้นเอง (query) เช่น "กาแฟ"
class ReadingTopic {
  const ReadingTopic._({this.preset, this.query});

  static const any = ReadingTopic._();
  const ReadingTopic.preset(ArticleTag tag) : this._(preset: tag);
  const ReadingTopic.search(String text) : this._(query: text);

  final ArticleTag? preset;
  final String? query;

  bool get isAny => preset == null && (query == null || query!.trim().isEmpty);

  /// ค่าที่ใช้เป็นแท็กของบทความ (null = ไม่มีหมวด)
  String? get tag => preset?.id ?? (isAny ? null : query!.trim());

  /// สร้างกลับจากแท็กที่เก็บไว้ (เช่น ใน SharedPreferences)
  factory ReadingTopic.fromTag(String? tag) {
    if (tag == null || tag.trim().isEmpty) return any;
    final preset = ArticleTag.fromId(tag);
    return preset != null
        ? ReadingTopic.preset(preset)
        : ReadingTopic.search(tag);
  }
}
