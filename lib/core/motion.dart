import 'package:flutter/material.dart';

/// ค่าการเคลื่อนไหวของทั้งแอปรวมไว้ที่เดียว ใช้ token ของ Material 3 (`Durations`, `Easing`)
///
/// หลักที่ใช้: "เร็วตอนต้น ช้าตอนปลาย" (decelerate) ของเข้ามาถึงตำแหน่งเร็ว
/// แล้วค่อยๆ ชะลอเข้าที่ สายตาไม่ต้องไล่ตามนาน จึงไม่ปวดตา
/// ใช้ easeOutCubic (นุ่มกว่า emphasizedDecelerate ที่พุ่งออกตัวแรงมาก) และเวลายาวกว่าค่า
/// มาตรฐานของ Material นิดหน่อย ให้ทุกอย่างค่อยๆ เคลื่อน ไม่วูบไว
abstract final class AppMotion {
  // ---- เปลี่ยนหน้า ----
  /// เปิดหน้าใหม่: เร็วตอนต้น ช้าตอนปลาย
  static const Curve pageEnter = Curves.easeOutCubic;

  /// ตอนย้อนกลับ animation วิ่งถอยหลัง (1 → 0): curve แบบ accelerate จึงกลายเป็น
  /// "เร็วตอนต้น ช้าตอนปลาย" เหมือนกัน
  static const Curve pageExit = Curves.easeInCubic;

  /// เวลาเปลี่ยนหน้า (ค่าเดิมของ Flutter = 300ms)
  static const Duration page = Duration(milliseconds: 450);

  /// หน้าใหม่เลื่อนเข้ามาแค่ 6% ของความกว้าง (ไม่ใช่ทั้งจอ) + fade → นุ่มกว่า
  static const Offset pageSlideFrom = Offset(0.06, 0);

  /// หน้าเดิมขยับถอยไปเล็กน้อยตอนมีหน้าใหม่มาทับ
  static const Offset pageSlideAway = Offset(-0.03, 0);

  // ---- กล่อง / การ์ดปรากฏ ----
  static const Duration entrance = Durations.long2; // 500ms
  static const Curve entranceCurve = Curves.easeOutCubic;

  /// การ์ดเริ่มต่ำกว่าตำแหน่งจริง 12 px แล้วเลื่อนขึ้น
  static const double entranceRise = 12;

  /// ระยะห่างของแต่ละใบตอนไล่กันเข้ามา และจำนวนใบสูงสุดที่ไล่ (ใบหลังจากนั้นมาพร้อมกัน)
  static const Duration stagger = Duration(milliseconds: 70);
  static const int maxStaggered = 8;

  // ---- กด / เลือก ----
  static const Duration press = Durations.short4; // 200ms
  static const Curve pressCurve = Easing.standard;

  /// การ์ดยุบลงตอนนิ้วแตะ
  static const double pressedScale = 0.97;

  /// ชิปที่ถูกเลือกขยายขึ้นเล็กน้อย
  static const double selectedScale = 1.05;
  static const Duration select = Durations.medium2; // 300ms

  /// ไฮไลต์ที่เลื่อนตามเนื้อหา (ย่อหน้าที่ TTS อ่าน, เลื่อนจอไปหาย่อหน้า)
  static const Duration highlight = Durations.medium4; // 400ms
  static const Duration scrollTo = Durations.long4; // 600ms

  /// ผู้ใช้เปิด "ลดการเคลื่อนไหว" (Reduce Motion) ในเครื่อง → ปิด effect ตกแต่งทั้งหมด
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// การเปลี่ยนหน้าของทั้งแอป: fade + เลื่อนเข้ามาสั้นๆ ด้วย curve "เร็วต้น ช้าปลาย"
///
/// ตั้งไว้ใน ThemeData.pageTransitionsTheme ทุก MaterialPageRoute จึงใช้แบบนี้เองอัตโนมัติ
/// ไม่ต้องแก้ Navigator.push ทีละจุด
class GentlePageTransitionsBuilder extends PageTransitionsBuilder {
  const GentlePageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    // animation = หน้านี้กำลังเข้า/ออก, secondaryAnimation = มีหน้าใหม่มาทับหน้านี้
    final enter = CurvedAnimation(
      parent: animation,
      curve: AppMotion.pageEnter,
      reverseCurve: AppMotion.pageExit,
    );
    final away = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.pageEnter,
      reverseCurve: AppMotion.pageExit,
    );
    return SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: AppMotion.pageSlideAway,
      ).animate(away),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween(
            begin: AppMotion.pageSlideFrom,
            end: Offset.zero,
          ).animate(enter),
          child: child,
        ),
      ),
    );
  }
}
