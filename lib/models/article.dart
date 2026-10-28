import 'content_language.dart';

/// บทความที่ดึงมาจากแหล่งข้อมูล (ตอนนี้คือ Wikipedia)
/// อยู่ใน memory ระหว่างอ่าน และถูกเก็บลง SharedPreferences ถ้าผู้ใช้พักการอ่านไว้
class Article {
  const Article({
    required this.sourceId,
    required this.pageId,
    required this.title,
    required this.content,
    required this.url,
    required this.language,
    this.topic,
    this.headings = const [],
  });

  /// แหล่งข้อมูล เช่น "wikipedia" (ดู ArticleSource)
  final String sourceId;

  /// id ของบทความในแหล่งข้อมูลนั้น (Wikipedia = pageid ระบุบทความได้แน่นอน แม้ชื่อจะเปลี่ยน)
  final int pageId;
  final String title;

  /// เนื้อหาแบบข้อความล้วน (plain text) สำหรับแสดงให้อ่าน
  final String content;

  /// ลิงก์ไปหน้าบทความจริง ใช้กับปุ่ม "ค้นต่อ"
  final String url;
  final ContentLanguage language;

  /// หมวดที่เลือกตอนสุ่ม (id หมวดยอดฮิต หรือคำที่ค้นเอง) null = สุ่มทุกหมวด
  final String? topic;

  /// ย่อหน้าที่เป็นหัวข้อของบทความ (หน้าอ่านแสดงเป็นตัวหนา) ว่าง = ไม่รู้ว่าบรรทัดไหนเป็นหัวข้อ
  final List<String> headings;

  bool isHeading(String paragraph) => headings.contains(paragraph);

  /// รหัสบทความที่ไม่ซ้ำกันข้ามแหล่ง/ภาษา ใช้กันการสุ่มเจอบทความที่เคยอ่านแล้ว
  String get readKey => readKeyOf(sourceId, language.code, pageId);

  static String readKeyOf(String sourceId, String languageCode, int pageId) =>
      '$sourceId:$languageCode:$pageId';

  /// จำนวนตัวอักษรสูงสุดที่ส่งให้ AI และเก็บใน Firestore เป็น originalContent
  /// (จำกัดไว้เพื่อไม่ให้เกินโควตา token ของ API ฟรี)
  /// 5000 พอให้ครอบคลุมบทความเกือบทั้งเรื่องหลังตัดส่วนอ้างอิงแล้ว (3000 เดิมตัดส่วนท้ายจน AI
  /// มองไม่เห็นและบอกว่าผู้ใช้ "ขาดประเด็น" ที่จริงๆ เขียนไว้แล้ว)
  static const int referenceMaxChars = 5000;

  String get reference => content.length <= referenceMaxChars
      ? content
      : content.substring(0, referenceMaxChars);

  /// แบ่งเป็นย่อหน้า (ใช้แสดงผลและให้ TTS อ่านทีละย่อหน้า)
  List<String> get paragraphs => content
      .split(RegExp(r'\n+'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  // ---- แปลงเป็น/จาก JSON เพื่อเก็บใน SharedPreferences ----

  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'pageId': pageId,
    'title': title,
    'content': content,
    'url': url,
    'language': language.code,
    'topic': topic,
    'headings': headings,
  };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    sourceId: json['sourceId'] as String? ?? 'wikipedia',
    pageId: (json['pageId'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    url: json['url'] as String? ?? '',
    // เซสชันเก่าที่บันทึกก่อนมีหลายภาษาเป็นภาษาไทยทั้งหมด
    language: ContentLanguage.fromCode(
      json['language'] as String?,
      fallback: ContentLanguage.th,
    ),
    // เซสชันเก่าใช้ key "category"
    topic: (json['topic'] ?? json['category']) as String?,
    // เซสชันเก่าที่บันทึกก่อนมีหัวข้อ = ไม่มี key นี้
    headings: [for (final h in (json['headings'] as List?) ?? const []) '$h'],
  );
}
