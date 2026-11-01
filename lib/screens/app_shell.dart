import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../widgets/capsule_nav_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'review_screen.dart';
import 'stats_screen.dart';

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
    // ProfileScreen มาจาก lib/screens/profile_screen.dart
    MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
  );

  @override
  Widget build(BuildContext context) {
    // context.l10n มาจาก lib/l10n/l10n.dart
    final l10n = context.l10n;
    return Scaffold(
      // เนื้อหาเลื่อนลอดใต้แถบเมนูได้ ส่วนความสูงของแถบถูกส่งต่อเป็น MediaQuery padding ด้านล่าง
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          // HomeScreen มาจาก lib/screens/home_screen.dart
          HomeScreen(user: widget.user, onOpenProfile: _openProfile),
          // ReviewScreen มาจาก lib/screens/review_screen.dart
          ReviewScreen(user: widget.user, onOpenProfile: _openProfile),
          // StatsScreen มาจาก lib/screens/stats_screen.dart
          StatsScreen(user: widget.user, onOpenProfile: _openProfile),
        ],
      ),
      // CapsuleNavBar มาจาก lib/widgets/capsule_nav_bar.dart
      bottomNavigationBar: CapsuleNavBar(
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
        items: [
          // CapsuleNavItem มาจาก lib/widgets/capsule_nav_bar.dart
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
