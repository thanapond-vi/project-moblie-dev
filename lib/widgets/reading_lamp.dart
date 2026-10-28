import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/theme.dart';

/// พื้นหลัง "โคมไฟอ่านหนังสือ": แสง radial gradient นุ่มๆ บนพื้นสีถ่านด้าน
///
/// - แตะ/ลากนิ้ว → แสงค่อยๆ ไหลตามนิ้วแบบหน่วง (lerp ทุกเฟรม) ให้ความรู้สึกช้าและสงบ
/// - ไม่ได้แตะเกิน 3 วินาทีระหว่างจับเวลา → แสงกลับไปอยู่หลังการ์ดบทความ แล้ว "หายใจ" สว่าง-หรี่ช้าๆ
///
/// ใช้ Ticker (callback ทุกเฟรม) + ValueNotifier ที่ผูกกับ CustomPainter โดยตรง
/// จึงวาดใหม่แค่ชั้นพื้นหลัง ไม่ rebuild widget ของบทความทุกเฟรม
class ReadingLampBackground extends StatefulWidget {
  const ReadingLampBackground({
    super.key,
    required this.active,
    required this.child,
  });

  /// true = กำลังจับเวลาอ่าน (เปิดโหมดหายใจได้เมื่อไม่ได้แตะจอ)
  final bool active;
  final Widget child;

  @override
  State<ReadingLampBackground> createState() => _ReadingLampBackgroundState();
}

class _ReadingLampBackgroundState extends State<ReadingLampBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  /// สถานะที่ painter ใช้วาด (เปลี่ยนทุกเฟรม → painter วาดใหม่เอง)
  final _lamp = ValueNotifier(const _LampState(Offset(0.5, 0.35), 0));

  /// ตำแหน่งเป้าหมาย/ปัจจุบัน เก็บเป็นสัดส่วน 0–1 ของขนาดพื้นที่ (ไม่ผูกกับขนาดจอ)
  Offset _target = const Offset(0.5, 0.35);
  Offset _position = const Offset(0.5, 0.35);
  Size _size = Size.zero;

  Duration _lastTick = Duration.zero;
  Duration _lastPointer = Duration.zero;
  bool _pointerSeen = false;

  /// ไม่ได้แตะนานเท่านี้ → เข้าโหมดหายใจ
  static const _idleAfter = Duration(seconds: 3);

  /// ตำแหน่งพักของแสง = กลางค่อนบนของการ์ดบทความ
  static const _restPosition = Offset(0.5, 0.35);

  /// ค่าความหน่วง: ยิ่งน้อยยิ่งไหลช้า (ต่อวินาที)
  static const _damping = 2.2;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _lamp.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReadingLampBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // เริ่ม/หยุดจับเวลา → เริ่มหรือเลิกหายใจ
    if (oldWidget.active != widget.active) _wake();
  }

  /// เปิด Ticker อีกครั้งหลังจากหยุดพักไว้ (เวลาของ Ticker เริ่มนับจาก 0 ใหม่ทุกครั้งที่ start)
  void _wake() {
    if (_ticker.isActive) return;
    _lastTick = Duration.zero;
    _lastPointer = Duration.zero;
    _ticker.start();
  }

  void _onPointer(Offset local) {
    if (_size.isEmpty) return;
    _target = Offset(local.dx / _size.width, local.dy / _size.height);
    _pointerSeen = true;
    _wake();
    _lastPointer = _lastTick;
  }

  void _onTick(Duration now) {
    final dt = ((now - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _lastTick = now;

    final idle = !_pointerSeen || now - _lastPointer > _idleAfter;
    if (idle) _target = _restPosition;

    // lerp แบบไม่ขึ้นกับ frame rate: เข้าใกล้เป้าหมาย (1 - e^(-k·dt)) ทุกเฟรม
    final t = 1 - math.exp(-_damping * dt);
    _position = Offset.lerp(_position, _target, t)!;

    // หายใจ: sin รอบละ ~6 วินาที (0–1) ใช้เฉพาะตอนไม่ได้แตะและกำลังจับเวลา
    final breathingTarget = idle && widget.active
        ? (math.sin(now.inMilliseconds / 6000 * 2 * math.pi) + 1) / 2
        : 0.0;
    final breathing = lerpDouble(_lamp.value.breathing, breathingTarget, t)!;

    _lamp.value = _LampState(_position, breathing);

    // แสงนิ่งแล้วและไม่ได้หายใจ (ไม่ได้จับเวลา) → หยุด Ticker ไม่ให้วาดซ้ำเปล่าๆ 60 ครั้ง/วินาที
    // ประหยัดแบตและไม่ต้องคำนวณ blur ของการ์ดใหม่ทุกเฟรม
    final settled =
        (_position - _target).distance < 0.0005 && breathing < 0.001;
    if (idle && !widget.active && settled) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ReadingLampColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        // Listener ฟังนิ้วโดยไม่แย่ง gesture: การเลื่อนอ่านบทความยังทำงานปกติ
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) => _onPointer(e.localPosition),
          onPointerMove: (e) => _onPointer(e.localPosition),
          child: CustomPaint(
            painter: _LampPainter(_lamp, colors: colors),
            child: widget.child,
          ),
        );
      },
    );
  }
}

@immutable
class _LampState {
  const _LampState(this.position, this.breathing);

  final Offset position;
  final double breathing;
}

class _LampPainter extends CustomPainter {
  // ส่ง notifier เป็น repaint: painter วาดใหม่ทุกครั้งที่ค่าเปลี่ยน โดยไม่ต้อง setState
  _LampPainter(this.lamp, {required this.colors}) : super(repaint: lamp);

  final ValueNotifier<_LampState> lamp;
  final ReadingLampColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // พื้นตามธีม (โหมดมืดเป็นสีถ่านด้าน โหมดสว่างเป็นกระดาษอุ่น)
    canvas.drawRect(rect, Paint()..color = colors.canvas);

    final state = lamp.value;
    final center = Offset(
      state.position.dx * size.width,
      state.position.dy * size.height,
    );
    // รัศมีใหญ่ (เกือบเต็มจอ) + หายใจ = ขยาย/สว่างขึ้นเล็กน้อย
    final radius = size.shortestSide * (0.85 + 0.12 * state.breathing);
    // ความทึบตามสเปก 0.08–0.12 คูณความเข้มของธีม (โหมดสว่างจางกว่า จะได้ไม่ดูเป็นคราบ)
    final core = (0.08 + 0.04 * state.breathing) * colors.glowStrength;

    final shader = RadialGradient(
      colors: [
        colors.glowCore.withValues(alpha: core),
        colors.glowHalo.withValues(alpha: core * 0.75),
        colors.glowHalo.withValues(alpha: 0),
      ],
      stops: const [0, 0.45, 1],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_LampPainter old) => old.colors != colors;
}
