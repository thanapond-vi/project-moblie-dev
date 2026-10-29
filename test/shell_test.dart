import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/core/theme.dart';
import 'package:keep/widgets/capsule_nav_bar.dart';

// แถบเมนูแคปซูลด้านล่าง: เลือกแท็บได้ บอกสถานะ "เลือกอยู่" กับโปรแกรมอ่านหน้าจอ และไม่ล้นที่ตัวอักษร 3 เท่า
void main() {
  const items = [
    CapsuleNavItem(
      icon: Icons.local_library_outlined,
      selectedIcon: Icons.local_library,
      label: 'Library',
    ),
    CapsuleNavItem(
      icon: Icons.psychology_outlined,
      selectedIcon: Icons.psychology,
      label: 'Review',
    ),
    CapsuleNavItem(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      label: 'Stats',
    ),
  ];

  Widget app({double textScale = 1}) {
    var index = 0;
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Text('tab $index'),
            bottomNavigationBar: CapsuleNavBar(
              items: items,
              selectedIndex: index,
              onSelected: (i) => setState(() => index = i),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('แตะแท็บ → สลับแท็บ และ semantics บอกว่าแท็บไหนถูกเลือก', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    expect(find.text('tab 0'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Library')),
      matchesSemantics(
        label: 'Library',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('tab 2'), findsOneWidget);
    expect(find.byIcon(Icons.insights), findsOneWidget);
    handle.dispose();
  });

  testWidgets('ตัวอักษร 3 เท่า: ไม่ล้น ปุ่มสูงอย่างน้อย 48', (tester) async {
    await tester.pumpWidget(app(textScale: 3));
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.bySemanticsLabel('Review'));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
