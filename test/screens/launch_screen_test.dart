import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/core/theme.dart';
import 'package:keep/l10n/gen/app_localizations.dart';
import 'package:keep/screens/launch_screen.dart';
import 'package:keep/widgets/keep_logo.dart';

// หน้าเปิดแอป: ประกอบโลโก้ → กะพริบ → สว่างนิ่ง แล้วไปต่อเอง (ทดสอบแบบไม่มีเสียง)
void main() {
  Widget app({required VoidCallback onDone, bool reduceMotion = false}) =>
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: LaunchScreen(onDone: onDone, sound: false),
        ),
      );

  testWidgets('เล่นจบแล้วไปต่อเอง โลโก้ประกอบครบ', (tester) async {
    var done = 0;
    await tester.pumpWidget(app(onDone: () => done++));
    // ตอนเริ่ม โคมไฟยังไม่ปรากฏ
    expect(tester.widget<KeepLogo>(find.byType(KeepLogo)).lamp, 0);
    await tester.pump(LaunchScreen.total);
    final logo = tester.widget<KeepLogo>(find.byType(KeepLogo));
    expect((logo.lamp, logo.book, logo.beam), (1.0, 1.0, 1.0));
    expect(logo.lampShift, 0);
    expect(done, 0); // ค้างโลโก้ไว้อีกนิดก่อนไปต่อ
    // นาฬิกาของอนิเมชันเริ่มนับที่เฟรมถัดไป จึงจบช้ากว่า total หนึ่งเฟรม + ค้างไว้ 300ms
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
    expect(done, 1);
  });

  testWidgets('แตะเพื่อข้ามได้ทันที', (tester) async {
    var done = 0;
    await tester.pumpWidget(app(onDone: () => done++));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(LaunchScreen));
    expect(done, 1);
    await tester.pump(LaunchScreen.total);
    expect(done, 1); // ไม่เรียกซ้ำตอนอนิเมชันจบ
  });

  testWidgets('Reduce Motion: โลโก้นิ่งเต็มดวงตั้งแต่แรก ไม่กะพริบ', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(app(onDone: () => done++, reduceMotion: true));
    final logo = tester.widget<KeepLogo>(find.byType(KeepLogo));
    expect((logo.lamp, logo.book, logo.beam), (1.0, 1.0, 1.0));
    await tester.pump(const Duration(milliseconds: 900));
    expect(done, 1);
  });

  test(
    'กะพริบแบบไม่มืดสนิท: หลังไฟติดแล้วไม่ต่ำกว่า 30% และจบที่สว่างเต็ม',
    () {
      final curve = LaunchScreen.flicker;
      var lowest = 1.0;
      // ข้ามช่วงไฟติดครั้งแรก (0 → 0.7 ใน 0.10 จาก 1.44 วินาที)
      for (var t = 0.1 / 1.44; t <= 1.0; t += 0.002) {
        final v = curve.transform(t);
        if (v < lowest) lowest = v;
      }
      expect(lowest, greaterThanOrEqualTo(0.3 - 1e-9));
      expect(curve.transform(1.0), 1.0);
    },
  );
}
