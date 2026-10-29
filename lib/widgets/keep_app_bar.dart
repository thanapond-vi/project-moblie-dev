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
          const KeepLogo(size: 28),
          const SizedBox(width: AppSpacing.xs),
          Text('KEEP', style: AppTheme.wordmark(context)),
        ],
      ),
      actions: [
        ValueListenableBuilder<UserProfile?>(
          valueListenable: ProfileService.instance.current,
          builder: (context, profile, _) => IconButton(
            tooltip: context.l10n.profileSettingsTooltip,
            onPressed: onOpenProfile,
            icon: UserAvatar.of(profile, radius: 16),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}
