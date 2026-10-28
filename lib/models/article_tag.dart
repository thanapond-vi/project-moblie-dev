import 'package:flutter/material.dart';

/// หมวดยอดฮิต 5 หมวด ใช้ 2 อย่าง:
/// 1) ปุ่มเลือกหมวดก่อนสุ่มบทความ (ค้นด้วย `articletopic:` ของ Wikipedia)
/// 2) แท็กบนบันทึกการอ่าน (ไม่เกิน 3 แท็ก AI แนะนำ แล้วผู้ใช้แก้เองได้)
///
/// แท็กเก็บใน Firestore เป็น String: หมวดยอดฮิตเก็บเป็น id (เช่น "history")
/// ส่วนหัวข้อที่ผู้ใช้ค้นเองเก็บเป็นคำที่พิมพ์ (เช่น "กาแฟ") ชื่อที่แสดงดู l10n.dart
enum ArticleTag {
  technology(
    'technology',
    Icons.memory,
    'articletopic:technology|computing|engineering',
  ),
  science(
    'science',
    Icons.biotech,
    'articletopic:biology|chemistry|physics|space|earth-and-environment',
  ),
  history(
    'history',
    Icons.history_edu,
    'articletopic:history|military-and-warfare',
  ),
  biographies('biographies', Icons.person_outline, 'articletopic:biography'),
  culture(
    'culture',
    Icons.palette_outlined,
    'articletopic:literature|music|visual-arts|performing-arts|philosophy-and-religion|food-and-drink',
  );

  const ArticleTag(this.id, this.icon, this.searchQuery);

  /// ค่าที่เก็บใน Firestore และใช้คุยกับ AI ห้ามเปลี่ยนหลังมีข้อมูลแล้ว
  final String id;
  final IconData icon;

  /// คำค้นที่ส่งให้ระบบค้นหาของ Wikipedia (`articletopic:` = หัวข้อที่ Wikipedia
  /// จัดให้ทุกบทความอัตโนมัติด้วยโมเดล ML ใช้ได้ทุกภาษา, `|` = หัวข้อใดหัวข้อหนึ่ง)
  final String searchQuery;

  static const int maxPerArticle = 3;

  static ArticleTag? fromId(String? id) {
    for (final t in ArticleTag.values) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// ทำความสะอาด list แท็ก (จาก Firestore / AI): ตัดค่าว่าง, ตัดซ้ำ, เก็บไม่เกิน 3
  static List<String> normalize(Iterable<Object?>? tags) {
    final result = <String>[];
    for (final raw in tags ?? const []) {
      final tag = raw?.toString().trim() ?? '';
      if (tag.isEmpty || tag.length > 40) continue;
      // หมวดยอดฮิตเทียบแบบไม่สนตัวพิมพ์ใหญ่เล็ก เก็บเป็น id มาตรฐาน
      final preset = fromId(tag.toLowerCase());
      final value = preset?.id ?? tag;
      if (!result.contains(value)) result.add(value);
      if (result.length == maxPerArticle) break;
    }
    return result;
  }
}
