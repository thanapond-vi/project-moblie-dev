import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/core/theme.dart';
import 'package:keep/widgets/keep_logo.dart';

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

  group('AppTheme tokens', () {
    test(
      'โหมดมืด = Obsidian Sage, โหมดสว่าง = Warm Paper (พื้นเดียวกับโคมไฟ)',
      () {
        expect(
          AppTheme.dark().colorScheme.surface,
          ReadingLampColors.dark.canvas,
        );
        expect(
          AppTheme.light().colorScheme.surface,
          ReadingLampColors.light.canvas,
        );
        expect(AppTheme.dark().colorScheme.primary, const Color(0xFF5AF0B3));
      },
    );

    test('สเกลตัวอักษรจาก Stitch: ขนาดและระยะบรรทัดเป็น px', () {
      final text = AppTheme.dark().textTheme;
      expect(text.displaySmall!.fontSize, 28);
      expect(text.titleMedium!.fontSize, 16);
      expect(text.titleMedium!.height! * 16, closeTo(24, 1e-9));
      expect(text.labelSmall!.fontWeight, FontWeight.w600);
    });

    test('ลงทะเบียนสีโลโก้ทั้งสองโหมด', () {
      expect(AppTheme.dark().extension<KeepLogoColors>(), KeepLogoColors.dark);
      expect(
        AppTheme.light().extension<KeepLogoColors>(),
        KeepLogoColors.light,
      );
      final mid = KeepLogoColors.light.lerp(KeepLogoColors.dark, 1);
      expect(mid.lamp, KeepLogoColors.dark.lamp);
    });
  });

  group('KeepLogo', () {
    testWidgets('ไม่มี label = ภาพตกแต่ง, มี label = อ่านออกเสียงได้', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Column(
            children: [
              KeepLogo(),
              KeepLogo(semanticLabel: 'KEEP logo'),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('KEEP logo'), findsOneWidget);
      handle.dispose();
    });

    test('วาดใหม่เมื่อส่วนใดส่วนหนึ่งเปลี่ยน', () {
      final a = KeepLogoPainter(colors: KeepLogoColors.dark);
      expect(
        a.shouldRepaint(KeepLogoPainter(colors: KeepLogoColors.dark)),
        isFalse,
      );
      expect(
        a.shouldRepaint(
          KeepLogoPainter(colors: KeepLogoColors.dark, beam: 0.2),
        ),
        isTrue,
      );
    });
  });
}
