import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/spacing.dart';
import '../l10n/l10n.dart';
import '../widgets/capsule_nav_bar.dart';
import '../widgets/keep_app_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// โครงหลักหลังล็อกอิน: 3 แท็บ (คลัง / ทบทวน / สถิติ) กับแถบเมนูแคปซูลลอยด้านล่าง
/// IndexedStack เก็บสถานะของทุกแท็บไว้ สลับแท็บแล้วกลับมารายการยังอยู่ที่เดิม
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.user});

  final User user;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;

  void _openProfile() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      // เนื้อหาเลื่อนลอดใต้แถบเมนูได้ ส่วนความสูงของแถบถูกส่งต่อเป็น MediaQuery padding ด้านล่าง
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(user: widget.user, onOpenProfile: _openProfile),
          _ComingSoonTab(
            icon: Icons.psychology_outlined,
            title: l10n.navReview,
            body: l10n.reviewComingSoonBody,
            onOpenProfile: _openProfile,
          ),
          _ComingSoonTab(
            icon: Icons.insights_outlined,
            title: l10n.navStats,
            body: l10n.statsComingSoonBody,
            onOpenProfile: _openProfile,
          ),
        ],
      ),
      bottomNavigationBar: CapsuleNavBar(
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
        items: [
          CapsuleNavItem(
            icon: Icons.local_library_outlined,
            selectedIcon: Icons.local_library,
            label: l10n.navLibrary,
          ),
          CapsuleNavItem(
            icon: Icons.psychology_outlined,
            selectedIcon: Icons.psychology,
            label: l10n.navReview,
          ),
          CapsuleNavItem(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights,
            label: l10n.navStats,
          ),
        ],
      ),
    );
  }
}

/// แท็บที่ยังไม่เปิดใช้ (รอ Phase B: ระบบทบทวนแบบเว้นระยะ)
class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({
    required this.icon,
    required this.title,
    required this.body,
    required this.onOpenProfile,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: KeepAppBar(onOpenProfile: onOpenProfile),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: scheme.secondary),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.comingSoon,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.tertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
