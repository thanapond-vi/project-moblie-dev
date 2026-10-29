import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/core/theme.dart';
import 'package:keep/l10n/gen/app_localizations.dart';
import 'package:keep/models/user_profile.dart';
import 'package:keep/widgets/avatar_widgets.dart';

// แถวตัวละคร (หน้าตั้งค่าเริ่มต้น + แผ่นเปลี่ยนรูปในโปรไฟล์)
void main() {
  testWidgets(
    'ตัวที่เลือกมีป้ายถูก + semantics บอกว่าเลือกอยู่ และแตะเปลี่ยนได้',
    (tester) async {
      final handle = tester.ensureSemantics();
      AvatarPreset? tapped;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AvatarPicker(
              selected: AvatarPreset.cat,
              photo: null,
              onPreset: (p) => tapped = p,
              onPhoto: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(AvatarPreset.cat.name)),
        isSemantics(isSelected: true, isButton: true),
      );
      final other = AvatarPreset.values.firstWhere(
        (p) => p != AvatarPreset.cat,
      );
      await tester.tap(find.bySemanticsLabel(other.name));
      expect(tapped, other);
      handle.dispose();
    },
  );
}
