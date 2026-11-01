import 'package:flutter/material.dart';

import '../core/spacing.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'avatar_widgets.dart';
import 'keep_logo.dart';

/// แถบบนของทุกแท็บ: โลโก้ + KEEP ทางซ้าย, รูปโปรไฟล์ทางขวา (แตะ = เปิดโปรไฟล์และตั้งค่า)
class KeepAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KeepAppBar({super.key, required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // KeepLogo มาจาก lib/widgets/keep_logo.dart
          const KeepLogo(size: 28),
          // AppSpacing มาจาก lib/core/spacing.dart
          const SizedBox(width: AppSpacing.xs),
          // AppTheme มาจาก lib/core/theme.dart
          Text('KEEP', style: AppTheme.wordmark(context)),
        ],
      ),
      actions: [
        // UserProfile มาจาก lib/models/user_profile.dart
        ValueListenableBuilder<UserProfile?>(
          // ProfileService มาจาก lib/services/profile_service.dart
          valueListenable: ProfileService.instance.current,
          builder: (context, profile, _) => IconButton(
            // context.l10n มาจาก lib/l10n/l10n.dart
            tooltip: context.l10n.profileSettingsTooltip,
            onPressed: onOpenProfile,
            // UserAvatar มาจาก lib/widgets/avatar_widgets.dart
            icon: UserAvatar.of(profile, radius: 16),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}
