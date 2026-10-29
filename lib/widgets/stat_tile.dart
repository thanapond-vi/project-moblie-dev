import 'package:flutter/material.dart';

import '../core/radius.dart';
import '../core/spacing.dart';
import '../l10n/l10n.dart';
import 'animated_counter.dart';

/// ช่องสถิติเล็ก (การ์ดบนหน้า Home, การ์ดโปรไฟล์): ตัวเลขนับขึ้น + หน่วย + ป้ายชื่อ
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.unit,
  });

  /// null = ยังไม่มีข้อมูล แสดงขีด
  final int? value;
  final String label;
  final Color color;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final number = theme.textTheme.titleLarge?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
    );
    final v = value;
    // อ่านเป็นข้อความเดียว "ป้าย: ค่า หน่วย" (ไม่อ่านตัวเลขระหว่างนับขึ้น หรือขีดว่า "dash")
    final spoken = v == null
        ? '$label: ${context.l10n.noData}'
        : '$label: $v${unit == null ? '' : ' $unit'}';
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: AppRadius.controlAll,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ตัวเลขยาว/ตัวอักษรใหญ่ → ย่อให้พอดีช่อง ไม่ล้น
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  v == null
                      ? Text('–', style: number)
                      : AnimatedCounter(value: v, style: number),
                  if (unit != null && v != null) ...[
                    const SizedBox(width: 2),
                    Text(
                      unit!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
