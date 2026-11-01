import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/radius.dart';
import '../core/spacing.dart';

/// ปุ่มหนึ่งช่องในแถบเมนูล่าง
class CapsuleNavItem {
  const CapsuleNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// แถบเมนูล่างแบบแคปซูลลอย (จาก Stitch): ลอยเหนือเนื้อหา ขอบบางเส้นเดียว ไม่มีเงา
/// ช่องที่เลือกอยู่มีพื้นเม็ดยาสี secondaryContainer ค่อยๆ เลื่อนสีเข้า/ออก
class CapsuleNavBar extends StatelessWidget {
  const CapsuleNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<CapsuleNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      // AppSpacing มาจาก lib/core/spacing.dart
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Material(
          color: scheme.surfaceContainerHigh,
          shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            // ตัวหนังสือในแถบเมนูขยายได้ไม่เกิน 1.5 เท่า (แบบ NavigationBar ของ Material)
            // ไม่งั้นที่ 3 เท่าแถบจะสูงจนบังเนื้อหาครึ่งจอ
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.5,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _CapsuleNavButton(
                        item: items[i],
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CapsuleNavButton extends StatelessWidget {
  const _CapsuleNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CapsuleNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      // ตัด semantics ของลูก (ไอคอน + ข้อความซ้ำ) จึงต้องผูก action แตะไว้ที่นี่เอง
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          // AppMotion มาจาก lib/core/motion.dart
          duration: AppMotion.reduced(context)
              ? Duration.zero
              : AppMotion.select,
          curve: AppMotion.pressCurve,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: selected
                ? scheme.secondaryContainer
                : scheme.surfaceContainerHigh,
            // AppRadius มาจาก lib/core/radius.dart
            borderRadius: AppRadius.pillAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? item.selectedIcon : item.icon, color: color),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
