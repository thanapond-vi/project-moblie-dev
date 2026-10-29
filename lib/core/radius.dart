import 'package:flutter/widgets.dart';

/// มุมโค้งทั้งแอป: ยิ่งชิ้นใหญ่ยิ่งโค้งมาก (ไม่ใช้ตัวเลขลอยๆ ใน widget)
abstract class AppRadius {
  /// ป้ายเล็ก รูปย่อ แถบสี
  static const double sm = 8;

  /// ปุ่ม ช่องพิมพ์ ไทล์ในการ์ด
  static const double control = 14;

  /// การ์ด
  static const double card = 20;

  /// แผ่นที่เลื่อนขึ้นจากล่าง แถบเมนูลอย การ์ดหน้าอ่าน
  static const double sheet = 24;

  /// เม็ดยา/ชิป (โค้งเต็มความสูง)
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius sheetAll = BorderRadius.all(Radius.circular(sheet));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
