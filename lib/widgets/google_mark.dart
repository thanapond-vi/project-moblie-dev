import 'dart:math' as math;

import 'package:flutter/material.dart';

/// เครื่องหมาย "G" ของ Google สำหรับปุ่มเข้าสู่ระบบ (แนวทางแบรนด์ของ Google กำหนดให้ใช้ G สี่สี)
///
/// ข้อยกเว้นของกฎ "ไม่มีสีในวิดเจ็ต": สีเหล่านี้เป็นสีแบรนด์ของ Google ที่ห้ามเปลี่ยนตามธีม
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _GooglePainter()),
  );
}

class _GooglePainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.width - stroke) / 2,
    );
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // องศาวัดตามเข็มนาฬิกาจากทางขวา: ช่องเปิดของ G อยู่มุมขวาบน (315°–360°)
    canvas.drawArc(rect, _rad(215), _rad(100), false, arc(_red));
    canvas.drawArc(rect, _rad(145), _rad(70), false, arc(_yellow));
    canvas.drawArc(rect, _rad(45), _rad(100), false, arc(_green));
    canvas.drawArc(rect, _rad(0), _rad(45), false, arc(_blue));
    // ขีดแนวนอนของ G จากกลางไปขอบขวา
    canvas.drawRect(
      Rect.fromLTRB(
        size.width / 2,
        size.height / 2 - stroke / 2,
        rect.right + stroke / 2,
        size.height / 2 + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}
