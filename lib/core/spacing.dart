/// ระยะห่างทั้งแอป: ทุกค่าเป็นผลคูณของหน่วยฐาน 4 (ไม่ใช้ตัวเลขลอยๆ ใน widget)
abstract class AppSpacing {
  static const double spaceUnit = 4;

  static const double xxs = spaceUnit; // 4
  static const double xs = 2 * spaceUnit; // 8
  static const double sm = 3 * spaceUnit; // 12
  static const double md = 4 * spaceUnit; // 16
  static const double lg = 5 * spaceUnit; // 20
  static const double xl = 6 * spaceUnit; // 24
  static const double xxl = 8 * spaceUnit; // 32

  /// เว้นท้ายรายการไม่ให้ปุ่มลอย (FAB) บังรายการสุดท้าย
  static const double fabClearance = 24 * spaceUnit; // 96
}
