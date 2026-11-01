import 'package:flutter/material.dart';

import 'motion.dart';
import 'radius.dart';

/// ธีมของ KEEP: "โคมไฟอ่านหนังสือบนโต๊ะ"
/// - โหมดมืด = Obsidian Sage (สีจาก Stitch: ถ่านอมเขียว + เขียวมิ้นต์ + อำพันของแสงไฟ)
/// - โหมดสว่าง = Warm Paper (กระดาษอุ่น หมึกเขียวเข้ม ใช้ลำดับชั้นเดียวกับโหมดมืด)
/// ตัวอักษรใช้ฟอนต์ระบบ (ไทย/จีนอ่านได้ดี) เอาแค่ขนาด/น้ำหนัก/ระยะบรรทัดจาก Stitch
class AppTheme {
  AppTheme._();

  static ThemeData light() =>
      _build(_warmPaper, ReadingLampColors.light, KeepLogoColors.light);
  static ThemeData dark() =>
      _build(_obsidianSage, ReadingLampColors.dark, KeepLogoColors.dark);

  /// Obsidian Sage: พื้นผิวไล่ระดับทีละนิด (lowest → highest) แทนการใช้เงา
  static const _obsidianSage = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF5AF0B3),
    onPrimary: Color(0xFF003825),
    primaryContainer: Color(0xFF34D399),
    onPrimaryContainer: Color(0xFF00563B),
    primaryFixed: Color(0xFF68FCBF),
    primaryFixedDim: Color(0xFF45DFA4),
    onPrimaryFixed: Color(0xFF002114),
    onPrimaryFixedVariant: Color(0xFF005137),
    secondary: Color(0xFF88D5C0),
    onSecondary: Color(0xFF00382D),
    secondaryContainer: Color(0xFF006050),
    onSecondaryContainer: Color(0xFF8CD8C3),
    secondaryFixed: Color(0xFFA4F2DB),
    secondaryFixedDim: Color(0xFF88D5C0),
    onSecondaryFixed: Color(0xFF002019),
    onSecondaryFixedVariant: Color(0xFF005142),
    tertiary: Color(0xFFFFD16D),
    onTertiary: Color(0xFF402D00),
    tertiaryContainer: Color(0xFFECB210),
    onTertiaryContainer: Color(0xFF614700),
    tertiaryFixed: Color(0xFFFFDF9F),
    tertiaryFixedDim: Color(0xFFF9BD22),
    onTertiaryFixed: Color(0xFF261A00),
    onTertiaryFixedVariant: Color(0xFF5C4300),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF121413),
    onSurface: Color(0xFFE2E3E0),
    surfaceDim: Color(0xFF121413),
    surfaceBright: Color(0xFF383A38),
    surfaceContainerLowest: Color(0xFF0D0F0E),
    surfaceContainerLow: Color(0xFF1A1C1B),
    surfaceContainer: Color(0xFF1E201F),
    surfaceContainerHigh: Color(0xFF282A29),
    surfaceContainerHighest: Color(0xFF333534),
    onSurfaceVariant: Color(0xFFBBCAC0),
    outline: Color(0xFF85948B),
    outlineVariant: Color(0xFF3C4A42),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE2E3E0),
    onInverseSurface: Color(0xFF2F3130),
    inversePrimary: Color(0xFF006C4B),
    surfaceTint: Color(0xFF45DFA4),
  );

  /// Warm Paper: กระดาษสีครีม หมึกเขียวเข้ม และอำพันเข้มพอจะอ่านออกบนกระดาษ
  /// (สีพื้นหลังเดียวกับ ReadingLampColors.light.canvas)
  static const _warmPaper = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006C4B),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFA8EFCF),
    onPrimaryContainer: Color(0xFF002114),
    primaryFixed: Color(0xFF68FCBF),
    primaryFixedDim: Color(0xFF45DFA4),
    onPrimaryFixed: Color(0xFF002114),
    onPrimaryFixedVariant: Color(0xFF005137),
    secondary: Color(0xFF2E6A5C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFB8EBDA),
    onSecondaryContainer: Color(0xFF002019),
    secondaryFixed: Color(0xFFA4F2DB),
    secondaryFixedDim: Color(0xFF88D5C0),
    onSecondaryFixed: Color(0xFF002019),
    onSecondaryFixedVariant: Color(0xFF005142),
    tertiary: Color(0xFF7A5900),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDF9F),
    onTertiaryContainer: Color(0xFF261A00),
    tertiaryFixed: Color(0xFFFFDF9F),
    tertiaryFixedDim: Color(0xFFF9BD22),
    onTertiaryFixed: Color(0xFF261A00),
    onTertiaryFixedVariant: Color(0xFF5C4300),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF6F1E7),
    onSurface: Color(0xFF1F2421),
    surfaceDim: Color(0xFFDDD5C7),
    surfaceBright: Color(0xFFFBF8F1),
    surfaceContainerLowest: Color(0xFFFFFCF5),
    surfaceContainerLow: Color(0xFFF0EADE),
    surfaceContainer: Color(0xFFEAE3D6),
    surfaceContainerHigh: Color(0xFFE4DCCE),
    surfaceContainerHighest: Color(0xFFDDD5C7),
    onSurfaceVariant: Color(0xFF47524C),
    outline: Color(0xFF77827C),
    outlineVariant: Color(0xFFCBC3B4),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2F3130),
    onInverseSurface: Color(0xFFF0EADE),
    inversePrimary: Color(0xFF5AF0B3),
    surfaceTint: Color(0xFF006C4B),
  );

  static ThemeData _build(
    ColorScheme scheme,
    ReadingLampColors lamp,
    KeepLogoColors logo,
  ) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = _textTheme(base.textTheme);
    return base.copyWith(
      textTheme: text,
      extensions: [lamp, logo],
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      // ช่องพิมพ์ "ยุบลง" = ทึบกว่าพื้นรอบข้างหนึ่งขั้น เส้นขอบบางจนแทบไม่เห็น
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          // AppRadius มาจาก lib/core/radius.dart
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      ).copyWith(color: scheme.surfaceContainerLow),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.controlAll,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.controlAll,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainer,
        // พื้นเข้ม + ตัวอักษรสีปกติ: อ่านออกทั้งสองโหมด (secondary สว่างเกินสำหรับตัวอักษรขาว)
        selectedColor: scheme.secondaryContainer,
        checkmarkColor: scheme.onSecondaryContainer,
        // ชิปทุกอันมีไอคอนหมวดอยู่แล้ว: คงไอคอนไว้ตอนเลือก ไม่แทนด้วยเครื่องหมายถูก
        showCheckmark: false,
        labelStyle: text.labelMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetAll),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      // เปลี่ยนหน้าแบบเดียวกันทุกระบบ: fade + เลื่อนสั้นๆ เร็วต้น ช้าปลาย (ดู core/motion.dart)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // GentlePageTransitionsBuilder มาจาก lib/core/motion.dart
          TargetPlatform.iOS: GentlePageTransitionsBuilder(),
          TargetPlatform.android: GentlePageTransitionsBuilder(),
          TargetPlatform.macOS: GentlePageTransitionsBuilder(),
        },
      ),
    );
  }

  static const _tabular = [FontFeature.tabularFigures()];

  /// สร้างสไตล์จากขนาด/ระยะบรรทัดเป็น px แบบใน Stitch (tracking เป็นสัดส่วนของขนาดตัวอักษร)
  static TextStyle? _step(
    TextStyle? base,
    double size,
    double lineHeight,
    FontWeight weight, {
    double tracking = 0,
    bool tabular = false,
  }) => base?.copyWith(
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: size * tracking,
    fontFeatures: tabular ? _tabular : null,
  );

  /// สเกลตัวอักษรจาก Stitch (Obsidian Sage) บนฟอนต์ระบบ
  /// ลำดับชั้นใช้น้ำหนัก + สี มากกว่าขนาด: ตัวเลขเด่น 700, หัวข้อ 600, ป้าย 600 ตัวเล็ก, เนื้อหา 400
  static TextTheme _textTheme(TextTheme b) => b.copyWith(
    displayLarge: _step(
      b.displayLarge,
      40,
      52,
      FontWeight.w700,
      tracking: -0.02,
      tabular: true,
    ),
    displayMedium: _step(
      b.displayMedium,
      32,
      42,
      FontWeight.w700,
      tracking: -0.015,
      tabular: true,
    ),
    // recall-stat: ตัวเลขสถิติหลักของหน้า
    displaySmall: _step(
      b.displaySmall,
      28,
      34,
      FontWeight.w700,
      tracking: -0.02,
      tabular: true,
    ),
    headlineLarge: _step(
      b.headlineLarge,
      26,
      34,
      FontWeight.w700,
      tracking: -0.01,
    ),
    headlineMedium: _step(
      b.headlineMedium,
      26,
      34,
      FontWeight.w700,
      tracking: -0.01,
    ),
    headlineSmall: _step(
      b.headlineSmall,
      22,
      30,
      FontWeight.w600,
      tracking: -0.01,
      tabular: true,
    ),
    titleLarge: _step(b.titleLarge, 18, 26, FontWeight.w600, tabular: true),
    titleMedium: _step(b.titleMedium, 16, 24, FontWeight.w600),
    titleSmall: _step(b.titleSmall, 15, 20, FontWeight.w600, tracking: 0.01),
    bodyLarge: _step(b.bodyLarge, 16, 28.8, FontWeight.w400),
    bodyMedium: _step(b.bodyMedium, 14, 22, FontWeight.w400),
    bodySmall: _step(b.bodySmall, 13, 18, FontWeight.w400),
    labelLarge: _step(b.labelLarge, 15, 20, FontWeight.w600, tracking: 0.01),
    labelMedium: _step(b.labelMedium, 13, 18, FontWeight.w600, tracking: 0.02),
    labelSmall: _step(b.labelSmall, 11, 16, FontWeight.w600, tracking: 0.04),
  );

  /// โลโก้ "KEEP" บน AppBar (หนา + เว้นระยะตัวอักษร)
  static TextStyle wordmark(BuildContext context) => Theme.of(context)
      .textTheme
      .titleLarge!
      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 2);

  /// โลโก้ "KEEP" ขนาดใหญ่ในหน้าเข้าสู่ระบบ
  /// (tracking กว้าง 0.28em แบบหน้า Sign In ใน Stitch)
  static TextStyle wordmarkLarge(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium!;
    return style.copyWith(letterSpacing: style.fontSize! * 0.28);
  }

  /// ช่องพิมพ์คำสรุป: body-reading-md (16 / 1.8) ตัวเล็กกว่าเนื้อหาบทความนิดให้เห็นข้อความมากขึ้น
  static TextStyle readingInput(BuildContext context) =>
      reading(context).copyWith(fontSize: 16);

  /// สไตล์ตัวอักษรสำหรับเนื้อหาบทความ: body-reading-lg 18 / 1.8 (ภาษาไทยอ่านง่ายขึ้นเมื่อระยะบรรทัดกว้าง)
  /// สีตัวอักษรมาจาก [ReadingLampColors] ซึ่งต่างกันตามธีม (โหมดมืดเป็นขาวอมครีม ลดแสงจ้า)
  static TextStyle reading(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge!.copyWith(
      height: 1.8,
      fontSize: 18,
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
    glowHalo: Color(0xFFF9BD22),
    glowStrength: 0.7,
    readingText: Color(0xFF1F2421),
  );

  /// โหมดมืด: สีถ่านด้าน อมเขียวเล็กน้อย แสงเต็ม
  static const dark = ReadingLampColors(
    canvas: Color(0xFF121413),
    glowCore: Color(0xFF34D399),
    glowHalo: Color(0xFFFFD16D),
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

/// สีของโลโก้ KEEP (โคมไฟ + ลำแสง + หนังสือ) แยกตามธีม
/// โหมดมืดใช้สีตรงจาก Stitch, โหมดสว่างเข้มขึ้นนิดให้เห็นบนกระดาษ
@immutable
class KeepLogoColors extends ThemeExtension<KeepLogoColors> {
  const KeepLogoColors({
    required this.lamp,
    required this.post,
    required this.arc,
    required this.beamTail,
    required this.book,
    required this.spine,
  });

  static const dark = KeepLogoColors(
    lamp: Color(0xFFFFD16D),
    post: Color(0xFF88D5C0),
    arc: Color(0xFF34D399),
    beamTail: Color(0xFF5AF0B3),
    book: Color(0xFF34D399),
    spine: Color(0xFF003825),
  );

  static const light = KeepLogoColors(
    lamp: Color(0xFFECB210),
    post: Color(0xFF2E6A5C),
    arc: Color(0xFF1FA67A),
    beamTail: Color(0xFF1FA67A),
    book: Color(0xFF22B583),
    spine: Color(0xFF003825),
  );

  /// หัวโคมไฟ และสีต้นของลำแสง (อำพัน)
  final Color lamp;

  /// เสาโคม
  final Color post;

  /// ฐานโค้งใต้โคม
  final Color arc;

  /// สีปลายลำแสงก่อนจางหาย
  final Color beamTail;

  /// หนังสือ
  final Color book;

  /// สันหนังสือ
  final Color spine;

  static KeepLogoColors of(BuildContext context) =>
      Theme.of(context).extension<KeepLogoColors>() ?? dark;

  @override
  KeepLogoColors copyWith({
    Color? lamp,
    Color? post,
    Color? arc,
    Color? beamTail,
    Color? book,
    Color? spine,
  }) {
    return KeepLogoColors(
      lamp: lamp ?? this.lamp,
      post: post ?? this.post,
      arc: arc ?? this.arc,
      beamTail: beamTail ?? this.beamTail,
      book: book ?? this.book,
      spine: spine ?? this.spine,
    );
  }

  @override
  KeepLogoColors lerp(ThemeExtension<KeepLogoColors>? other, double t) {
    if (other is! KeepLogoColors) return this;
    return KeepLogoColors(
      lamp: Color.lerp(lamp, other.lamp, t)!,
      post: Color.lerp(post, other.post, t)!,
      arc: Color.lerp(arc, other.arc, t)!,
      beamTail: Color.lerp(beamTail, other.beamTail, t)!,
      book: Color.lerp(book, other.book, t)!,
      spine: Color.lerp(spine, other.spine, t)!,
    );
  }
}
