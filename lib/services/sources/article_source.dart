import '../../models/article.dart';
import '../../models/content_language.dart';
import '../../models/reading_topic.dart';
import 'wikipedia_source.dart';

/// แหล่งข้อมูลบทความ 1 แหล่ง
///
/// แอปคุยกับแหล่งข้อมูลผ่าน interface นี้เท่านั้น ถ้าอนาคตจะเพิ่มแหล่งใหม่
/// (หรือให้ติดตั้งเป็น plugin) แค่เขียน class ที่ implements ArticleSource
/// แล้วเพิ่มเข้า [ArticleSources.all] หน้าจออื่นไม่ต้องแก้
abstract class ArticleSource {
  /// id ที่เก็บใน Firestore / SharedPreferences เช่น "wikipedia"
  String get id;

  /// ชื่อที่แสดงในแอป
  String get name;

  /// ภาษาที่แหล่งนี้รองรับ
  Set<ContentLanguage> get languages;

  /// สุ่มบทความ 1 เรื่อง
  /// - [topic]: หมวดยอดฮิต / คำค้นเอง / สุ่มทุกหมวด
  /// - [excludeKeys]: Article.readKey ของบทความที่ผู้ใช้อ่านไปแล้ว (ห้ามสุ่มซ้ำ)
  ///
  /// throw [TopicExhaustedException] ถ้าบทความในหมวดนั้นถูกอ่านครบหมดแล้ว
  Future<Article> fetchRandomArticle({
    required ContentLanguage language,
    required ReadingTopic topic,
    required Set<String> excludeKeys,
  });
}

/// บทความทุกเรื่องในหมวดนี้ถูกอ่านไปแล้ว (หน้าจอแสดงข้อความ "อ่านครบแล้ว")
class TopicExhaustedException implements Exception {
  const TopicExhaustedException();
}

/// รายชื่อแหล่งข้อมูลที่ติดตั้งในแอป (ตอนนี้มี Wikipedia แหล่งเดียว)
class ArticleSources {
  ArticleSources._();

  static final List<ArticleSource> all = [WikipediaSource()];

  static ArticleSource byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
