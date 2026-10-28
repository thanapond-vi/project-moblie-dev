import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/widgets/animated_counter.dart';
import 'package:keep/widgets/score_badge.dart';

// ทดสอบการเข้าถึง: Reduce Motion และตัวอักษรขนาดใหญ่ (ไม่ต้องใช้ Firebase/อินเทอร์เน็ต)
void main() {
  Widget reducedMotion(Widget child) => MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: MaterialApp(home: Scaffold(body: child)),
  );

  testWidgets('Reduce Motion: การ์ดสถิติแสดงป้ายและตัวเลขเต็มทันที', (
    tester,
  ) async {
    await tester.pumpWidget(
      reducedMotion(
        const StatRevealCard(
          icon: Icons.timer_outlined,
          label: 'Total reading',
          value: 42,
          unit: 'min',
          caption: 'All time',
          delay: Duration(milliseconds: 300),
        ),
      ),
    );
    expect(find.text('Total reading'), findsOneWidget);
    expect(find.textContaining('42', findRichText: true), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
  });

  testWidgets('Reduce Motion: ตัวนับคะแนนแสดงค่าสุดท้ายทันที', (tester) async {
    await tester.pumpWidget(reducedMotion(const AnimatedCounter(value: 85)));
    expect(find.text('85'), findsOneWidget);
  });

  testWidgets('Reduce Motion: ป้าย +X นาทีแสดงทันทีโดยไม่ย่อขยาย', (
    tester,
  ) async {
    await tester.pumpWidget(reducedMotion(const EarnedBadge(label: '+5 min')));
    expect(find.text('+5 min'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('+5 min'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('ตัวอักษรใหญ่ 3 เท่า: ป้ายคะแนน 3 หลักไม่ล้นวงกลม', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(3)),
        child: MaterialApp(
          home: Scaffold(body: Center(child: ScoreBadge(score: 100, size: 48))),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ScoreBadge)), const Size(48, 48));
  });
}
