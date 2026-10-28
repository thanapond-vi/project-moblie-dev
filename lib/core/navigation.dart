import 'package:flutter/widgets.dart';

/// แจ้งหน้าจอ (ที่ subscribe ไว้ด้วย RouteAware) เมื่อถูกเปิด/ถูกกลับมาแสดงอีกครั้ง
/// หน้าแรกใช้สั่งเล่น effect นับคะแนนใหม่ทุกครั้งที่ผู้ใช้กลับมา
///
/// ใช้ PageRoute (หน้าจอเต็ม) เท่านั้น ถ้าใช้ ModalRoute จะรวม dialog / bottom sheet ด้วย
/// แค่ปิดกล่องยืนยันก็จะนับคะแนนใหม่ ซึ่งไม่ใช่ "กลับมาที่หน้านี้" จริงๆ
final RouteObserver<PageRoute<void>> routeObserver = RouteObserver();
