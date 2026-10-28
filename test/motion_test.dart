import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/core/motion.dart';
import 'package:keep/core/theme.dart';
import 'package:keep/widgets/motion_widgets.dart';

// ทดสอบ effect การเคลื่อนไหว (ไม่ต้องใช้ Firebase/อินเทอร์เน็ต)
void main() {
  double opacityOf(WidgetTester tester) => tester
      .widget<Opacity>(
        find.ancestor(of: find.text('card'), matching: find.byType(Opacity)),
      )
      .opacity;

  testWidgets('EntranceFade: เริ่มโปร่งใส แล้วค่อยๆ ปรากฏจนเต็ม', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: EntranceFade(child: Text('card'))),
    );
    expect(opacityOf(tester), 0);
    await tester.pump(AppMotion.entrance ~/ 2);
    expect(opacityOf(tester), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(opacityOf(tester), 1);
  });

  testWidgets('เปิด Reduce Motion ในเครื่อง → แสดงทันที ไม่มี animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: EntranceFade(child: Text('card'))),
      ),
    );
    expect(find.text('card'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('card'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  test('เปลี่ยนหน้าแบบ "เร็วต้น ช้าปลาย": ครึ่งเวลาแรกเคลื่อนไปเกินครึ่งทาง', () {
    // เปิดหน้า: ที่เวลา 30% ต้องไปได้เกิน 50% ของระยะแล้ว
    expect(AppMotion.pageEnter.transform(0.3), greaterThan(0.5));
    // ย้อนกลับ (animation วิ่ง 1 → 0): ช่วงแรกของการย้อน (t จาก 1 ลงมา 0.7) ต้องเคลื่อนเยอะ
    expect(1 - AppMotion.pageExit.transform(0.7), greaterThan(0.5));
  });

  testWidgets(
    'ทุก MaterialPageRoute ใช้การเปลี่ยนหน้าแบบใหม่ และไปถึงหน้าปลายทางได้',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.light(),
          home: const Text('home'),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Text('next')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // ระหว่างเปลี่ยนหน้า มี FadeTransition จาก GentlePageTransitionsBuilder
      expect(
        find.ancestor(
          of: find.text('next'),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
    },
  );
}
