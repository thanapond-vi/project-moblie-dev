import 'package:flutter/material.dart';

import '../core/theme.dart';

/// โลโก้ KEEP: โคมไฟส่องลงบนหนังสือที่เปิดอยู่ (วาดจาก SVG ของหน้า Sign In ใน Stitch, viewBox 64×64)
///
/// แยกเป็น 3 ส่วนที่ปรับได้อิสระ เพื่อให้หน้าเปิดแอปทำอนิเมะชันประกอบโลโก้/ไฟกะพริบได้:
/// - [lamp] หัวโคม เสา และฐานโค้ง (0 = ซ่อน, 1 = เต็ม)
/// - [beam] ความสว่างของลำแสง (0 = ไฟดับ, 1 = สว่างปกติ)
/// - [book] หนังสือ (0 = ซ่อน, 1 = เต็ม)
/// ค่าเริ่มต้นทุกส่วน = 1 คือโลโก้นิ่งตามปกติ
///
/// [lampShift] / [bookShift] เลื่อนส่วนนั้นในแนวตั้ง (หน่วยของ viewBox 64, บวก = ลง)
/// ใช้ตอนประกอบโลโก้: โคมไฟลอยลงมา หนังสือลอยขึ้นมาบรรจบกัน
class KeepLogo extends StatelessWidget {
  const KeepLogo({
    super.key,
    this.size = 64,
    this.lamp = 1,
    this.beam = 1,
    this.book = 1,
    this.lampShift = 0,
    this.bookShift = 0,
    this.semanticLabel,
  });

  final double size;
  final double lamp;
  final double beam;
  final double book;
  final double lampShift;
  final double bookShift;

  /// null = เป็นภาพตกแต่ง โปรแกรมอ่านหน้าจอข้ามไป
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final logo = CustomPaint(
      size: Size.square(size),
      painter: KeepLogoPainter(
        // KeepLogoColors มาจาก lib/core/theme.dart
        colors: KeepLogoColors.of(context),
        lamp: lamp,
        beam: beam,
        book: book,
        lampShift: lampShift,
        bookShift: bookShift,
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: logo);
    return Semantics(image: true, label: semanticLabel, child: logo);
  }
}

class KeepLogoPainter extends CustomPainter {
  KeepLogoPainter({
    required this.colors,
    this.lamp = 1,
    this.beam = 1,
    this.book = 1,
    this.lampShift = 0,
    this.bookShift = 0,
  });

  final KeepLogoColors colors;
  final double lamp;
  final double beam;
  final double book;
  final double lampShift;
  final double bookShift;

  /// ความทึบของลำแสงตอนสว่างเต็มที่ (ตาม SVG ต้นฉบับ)
  static const _beamOpacity = 0.22;

  static final _lampHead = Path()
    ..moveTo(26, 12)
    ..cubicTo(26, 8.68629, 28.6863, 6, 32, 6)
    ..cubicTo(35.3137, 6, 38, 8.68629, 38, 12)
    ..lineTo(39.5, 19)
    ..lineTo(24.5, 19)
    ..close();

  static final _arc = Path()
    ..moveTo(22, 28)
    ..cubicTo(22, 28, 27, 30, 32, 30)
    ..cubicTo(37, 30, 42, 28, 42, 28);

  static final _beam = Path()
    ..moveTo(24, 20)
    ..lineTo(10, 52)
    ..lineTo(54, 52)
    ..lineTo(40, 20)
    ..close();

  static final _book = Path()
    ..moveTo(14, 48)
    ..cubicTo(19, 46, 27, 45.5, 32, 49)
    ..cubicTo(37, 45.5, 45, 46, 50, 48)
    ..lineTo(50, 39)
    ..cubicTo(45, 37, 37, 36.5, 32, 40)
    ..cubicTo(27, 36.5, 19, 37, 14, 39)
    ..close();

  Paint _stroke(Color color, double width, double opacity) => Paint()
    ..color = color.withValues(alpha: color.a * opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  Paint _fill(Color color, double opacity) =>
      Paint()..color = color.withValues(alpha: color.a * opacity);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);

    final beamAlpha = (beam.clamp(0.0, 1.0) * _beamOpacity).toDouble();
    if (beamAlpha > 0) {
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.lamp.withValues(alpha: beamAlpha),
          colors.beamTail.withValues(alpha: 0.3 * beamAlpha),
          colors.beamTail.withValues(alpha: 0),
        ],
        stops: const [0, 0.75, 1],
      ).createShader(const Rect.fromLTRB(10, 20, 54, 52));
      canvas.drawPath(_beam, Paint()..shader = shader);
    }

    final l = lamp.clamp(0.0, 1.0).toDouble();
    if (l > 0) {
      canvas.save();
      canvas.translate(0, lampShift);
      canvas.drawLine(
        const Offset(32, 19),
        const Offset(32, 30),
        _stroke(colors.post, 2.5, l),
      );
      canvas.drawPath(_arc, _stroke(colors.arc, 2, l));
      canvas.drawPath(_lampHead, _fill(colors.lamp, l));
      canvas.restore();
    }

    final b = book.clamp(0.0, 1.0).toDouble();
    if (b > 0) {
      canvas.save();
      canvas.translate(0, bookShift);
      canvas.drawPath(_book, _fill(colors.book, b));
      canvas.drawLine(
        const Offset(32, 40),
        const Offset(32, 49),
        _stroke(colors.spine, 2, b),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(KeepLogoPainter old) =>
      old.colors != colors ||
      old.lamp != lamp ||
      old.beam != beam ||
      old.book != book ||
      old.lampShift != lampShift ||
      old.bookShift != bookShift;
}
