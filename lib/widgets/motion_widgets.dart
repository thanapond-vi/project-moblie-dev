import 'package:flutter/material.dart';

import '../core/motion.dart';

/// กล่อง/การ์ดค่อยๆ ปรากฏ: fade + เลื่อนขึ้น 12 px (เร็วต้น ช้าปลาย) เล่นครั้งเดียวตอนสร้าง
///
/// [index] ใช้ไล่กันทีละใบ: ใบที่ n เริ่มช้ากว่าใบแรก n × 50 ms (สูงสุด 8 ใบ)
/// ทำแบบ implicit ด้วย TweenAnimationBuilder: ยืดเวลารวมตาม index แล้วใช้ Interval
/// ให้ช่วงแรกนิ่งไว้ → ได้ผลเหมือนหน่วงเวลา โดยไม่ต้องมี AnimationController / dispose
///
/// การ์ดในรายการต้องมี Key คงที่ (เช่น ValueKey(id)) เพื่อให้เล่นแค่ตอนใบนั้นปรากฏครั้งแรก
/// ไม่เล่นซ้ำทุกครั้งที่ข้อมูลใน Firestore อัปเดต
class EntranceFade extends StatelessWidget {
  const EntranceFade({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;

    final delay = AppMotion.stagger * index.clamp(0, AppMotion.maxStaggered);
    final total = AppMotion.entrance + delay;
    final start = delay.inMicroseconds / total.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: AppMotion.entranceCurve),
      // child ไม่ถูกสร้างใหม่ทุกเฟรม ขยับแค่ Opacity / Transform (ถูกที่สุดสำหรับ GPU)
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, AppMotion.entranceRise * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// การ์ดที่กดได้: ยุบลงเหลือ 97% ตอนนิ้วแตะ แล้วเด้งกลับตอนปล่อย
///
/// ใช้ Listener (ฟังนิ้วอย่างเดียว ไม่แย่ง gesture) จึงครอบ InkWell / Dismissible ได้
/// โดย onTap และการปัดลบยังทำงานปกติ
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child});

  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      // เริ่มเลื่อนจอ/ปัด ระบบจะยกเลิกการแตะ → ต้องคืนขนาดด้วย
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressedScale : 1,
        duration: AppMotion.press,
        curve: AppMotion.pressCurve,
        child: widget.child,
      ),
    );
  }
}

/// ชิป/ตัวเลือกที่ถูกเลือก ขยายขึ้นเล็กน้อย (5%) ให้เห็นชัดว่าเลือกอันไหนอยู่
class SelectedScale extends StatelessWidget {
  const SelectedScale({super.key, required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return AnimatedScale(
      scale: selected ? AppMotion.selectedScale : 1,
      duration: AppMotion.select,
      curve: AppMotion.entranceCurve,
      child: child,
    );
  }
}

/// ครอบทุก widget ในรายการด้วย [EntranceFade] ตามลำดับ → ส่วนต่างๆ ของหน้าค่อยๆ ไล่กันเข้ามา
/// ใช้กับ `ListView(children: staggered([...]))`
List<Widget> staggered(List<Widget> children) => [
  for (final (i, child) in children.indexed)
    EntranceFade(index: i, child: child),
];
