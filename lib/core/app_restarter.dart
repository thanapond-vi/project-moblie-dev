import 'package:flutter/widgets.dart';

/// ครอบทั้งแอปไว้เพื่อ "รีสตาร์ตแอป" จากภายใน (ใช้ตอนเปลี่ยนภาษา)
///
/// iOS ไม่อนุญาตให้แอปปิดตัวเองแล้วเปิดใหม่ จึงรีสตาร์ตด้วยการเปลี่ยน Key ของ widget ชั้นบนสุด
/// Flutter จะทิ้ง widget/State เดิมทั้งหมดแล้วสร้างใหม่ตั้งแต่ AuthGate → เหมือนเปิดแอปใหม่
class AppRestarter extends StatefulWidget {
  const AppRestarter({super.key, required this.child});

  final Widget child;

  static void restart(BuildContext context) =>
      context.findAncestorStateOfType<_AppRestarterState>()?._restart();

  @override
  State<AppRestarter> createState() => _AppRestarterState();
}

class _AppRestarterState extends State<AppRestarter> {
  Key _key = UniqueKey();

  void _restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
