import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/core/theme.dart';

// ทดสอบสีของหน้าอ่าน (ReadingLampColors) ที่ผูกกับ ThemeData
void main() {
  group('ReadingLampColors', () {
    test('ธีมสว่าง/มืดลงทะเบียนชุดสีของตัวเอง', () {
      expect(
        AppTheme.light().extension<ReadingLampColors>(),
        ReadingLampColors.light,
      );
      expect(
        AppTheme.dark().extension<ReadingLampColors>(),
        ReadingLampColors.dark,
      );
    });

    test('lerp: ปลายทั้งสองข้างได้ค่าเดิม ตรงกลางได้ค่าระหว่างกัน', () {
      const a = ReadingLampColors.light;
      const b = ReadingLampColors.dark;
      expect(a.lerp(b, 0).canvas, a.canvas);
      expect(a.lerp(b, 1).canvas, b.canvas);
      expect(a.lerp(b, 1).readingText, b.readingText);
      expect(a.lerp(b, 0.5).glowStrength, closeTo(0.85, 1e-9));
      expect(a.lerp(null, 0.5), same(a));
    });

    test('copyWith เปลี่ยนเฉพาะค่าที่ส่งมา', () {
      final copy = ReadingLampColors.light.copyWith(glowStrength: 0.3);
      expect(copy.glowStrength, 0.3);
      expect(copy.canvas, ReadingLampColors.light.canvas);
      expect(copy.readingText, ReadingLampColors.light.readingText);
    });

    testWidgets('ไม่มี extension ในธีม → ใช้ชุดสีสว่างเป็นค่าเริ่มต้น', (
      tester,
    ) async {
      late ReadingLampColors colors;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              colors = ReadingLampColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(colors, ReadingLampColors.light);
    });
  });

  testWidgets('AppTheme.reading ใช้สีตัวอักษรของธีมที่กำลังใช้', (
    tester,
  ) async {
    late TextStyle style;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            style = AppTheme.reading(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(style.color, ReadingLampColors.dark.readingText);
    expect(style.height, 1.8);
  });
}
