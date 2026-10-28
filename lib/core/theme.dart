import 'package:flutter/material.dart';

import 'motion.dart';

/// ธีมมินิมอลสำหรับการอ่าน: สีหลักโทนเขียวอมฟ้า พื้นหลังสะอาด ตัวอักษรระยะบรรทัดกว้าง
class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF2E7D6B);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [
        brightness == Brightness.dark
            ? ReadingLampColors.dark
            : ReadingLampColors.light,
      ],
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      // เปลี่ยนหน้าแบบเดียวกันทุกระบบ: fade + เลื่อนสั้นๆ เร็วต้น ช้าปลาย (ดู core/motion.dart)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: GentlePageTransitionsBuilder(),
          TargetPlatform.android: GentlePageTransitionsBuilder(),
          TargetPlatform.macOS: GentlePageTransitionsBuilder(),
        },
      ),
    );
    // แก้แค่น้ำหนัก/ตัวเลข ไม่แตะขนาด: ขนาดตัวอักษรมาจาก Typography ตามภาษา (ไทย/จีนสูงกว่าอังกฤษ)
    return theme.copyWith(textTheme: _textTheme(theme.textTheme));
  }

  static const _tabular = [FontFeature.tabularFigures()];

  /// ลำดับชั้นตัวอักษร: ใช้น้ำหนักแยกชั้นแทนการเพิ่มขนาด
  /// - หัวข้อใหญ่/ตัวเลขเด่น (headline, titleLarge) หนา 700 + ตัวเลขกว้างเท่ากัน (ไม่กระตุกตอนนับ)
  /// - ชื่อบทความในการ์ด (titleMedium) หนา 600
  static TextTheme _textTheme(TextTheme base) => base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: _tabular,
    ),
    headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: _tabular,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: _tabular,
    ),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );

  /// โลโก้ "KEEP" บน AppBar (หนา + เว้นระยะตัวอักษร)
  static TextStyle wordmark(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(letterSpacing: 2);

  /// โลโก้ "KEEP" ขนาดใหญ่ในหน้าเข้าสู่ระบบ
  static TextStyle wordmarkLarge(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(letterSpacing: 4);

  /// ช่องพิมพ์คำสรุป: ระยะบรรทัดแบบเนื้อหาบทความ แต่ตัวเล็กลงนิดให้เห็นข้อความมากขึ้น
  static TextStyle readingInput(BuildContext context) =>
      reading(context).copyWith(fontSize: 16);

  /// สไตล์ตัวอักษรสำหรับเนื้อหาบทความ (ภาษาไทยอ่านง่ายขึ้นเมื่อระยะบรรทัดกว้าง)
  /// สีตัวอักษรมาจาก [ReadingLampColors] ซึ่งต่างกันตามธีม (โหมดมืดเป็นขาวอมครีม ลดแสงจ้า)
  static TextStyle reading(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge!.copyWith(
      height: 1.8,
      fontSize: 17,
      color: ReadingLampColors.of(context).readingText,
    );
  }
}

/// สีของหน้าอ่านบทความ: พื้นโคมไฟ แสง และตัวอักษร แยกตามธีมใน [ThemeData.extensions]
/// ให้ widget อ่านค่าจากธีมโดยไม่ต้องเช็กโหมดมืดเอง
@immutable
class ReadingLampColors extends ThemeExtension<ReadingLampColors> {
  const ReadingLampColors({
    required this.canvas,
    required this.glowCore,
    required this.glowHalo,
    required this.glowStrength,
    required this.readingText,
  });

  /// โหมดสว่าง: กระดาษอุ่น แสงจางลง จะได้ไม่ดูเป็นคราบ
  static const light = ReadingLampColors(
    canvas: Color(0xFFF6F1E7),
    glowCore: Color(0xFF34D399),
    glowHalo: Color(0xFFFBBF24),
    glowStrength: 0.7,
    readingText: Color(0xFF1F2421),
  );

  /// โหมดมืด: สีถ่านด้าน อมเขียวเล็กน้อย แสงเต็ม
  static const dark = ReadingLampColors(
    canvas: Color(0xFF121413),
    glowCore: Color(0xFF34D399),
    glowHalo: Color(0xFFFBBF24),
    glowStrength: 1,
    readingText: Color(0xFFE9E6DF),
  );

  /// พื้นหลังโคมไฟ (ทึบ)
  final Color canvas;

  /// สีแสงตรงกลาง (เขียวมรกต)
  final Color glowCore;

  /// สีแสงรอบนอก (อำพัน)
  final Color glowHalo;

  /// ตัวคูณความเข้มของแสง
  final double glowStrength;

  /// สีตัวอักษรบทความ
  final Color readingText;

  static ReadingLampColors of(BuildContext context) =>
      Theme.of(context).extension<ReadingLampColors>() ?? light;

  @override
  ReadingLampColors copyWith({
    Color? canvas,
    Color? glowCore,
    Color? glowHalo,
    double? glowStrength,
    Color? readingText,
  }) {
    return ReadingLampColors(
      canvas: canvas ?? this.canvas,
      glowCore: glowCore ?? this.glowCore,
      glowHalo: glowHalo ?? this.glowHalo,
      glowStrength: glowStrength ?? this.glowStrength,
      readingText: readingText ?? this.readingText,
    );
  }

  @override
  ReadingLampColors lerp(ThemeExtension<ReadingLampColors>? other, double t) {
    if (other is! ReadingLampColors) return this;
    return ReadingLampColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      glowCore: Color.lerp(glowCore, other.glowCore, t)!,
      glowHalo: Color.lerp(glowHalo, other.glowHalo, t)!,
      glowStrength: glowStrength + (other.glowStrength - glowStrength) * t,
      readingText: Color.lerp(readingText, other.readingText, t)!,
    );
  }
}
