import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/motion.dart';
import '../core/spacing.dart';
import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import 'ui_helpers.dart';
import 'motion_widgets.dart';

/// รูปโปรไฟล์วงกลม: มีรูปของผู้ใช้เอง → แสดงรูปนั้น, ไม่มี → แสดงตัวละครสัตว์ที่เลือก
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.preset,
    this.photo,
    this.radius = 24,
  });

  // UserProfile มาจาก lib/models/user_profile.dart
  /// สร้างจากโปรไฟล์ (null = ยังโหลดไม่เสร็จ แสดงตัวละครเริ่มต้นไปก่อน)
  factory UserAvatar.of(UserProfile? profile, {double radius = 24}) =>
      UserAvatar(
        // AvatarPreset มาจาก lib/models/user_profile.dart
        preset: profile?.preset ?? AvatarPreset.cat,
        photo: profile?.avatarBytes,
        radius: radius,
      );

  final AvatarPreset preset;
  final Uint8List? photo;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = photo;
    return CircleAvatar(
      radius: radius,
      // MemoryImage = รูปจาก bytes ในหน่วยความจำ (ถอดจาก base64 ใน Firestore)
      // AssetImage  = รูปที่ฝังมากับแอป (ตัวละครสัตว์)
      backgroundImage: bytes != null
          ? MemoryImage(bytes)
          : AssetImage(preset.asset) as ImageProvider,
    );
  }
}

/// ตัวเลือกรูปโปรไฟล์: ตัวละครสัตว์ 5 แบบ + ปุ่มใช้รูปของตัวเอง (คลังรูป / กล้อง)
/// ใช้ทั้งในหน้าตั้งค่าเริ่มต้นและใน Settings
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.selected,
    required this.photo,
    required this.onPreset,
    required this.onPhoto,
  });

  /// ตัวละครที่เลือกอยู่ (ไม่มีกรอบเลือกถ้ากำลังใช้รูปของตัวเอง)
  final AvatarPreset selected;
  final Uint8List? photo;
  final ValueChanged<AvatarPreset> onPreset;
  final ValueChanged<Uint8List> onPhoto;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final bytes = await pickProfilePhoto(context, source);
    if (bytes != null) onPhoto(bytes);
  }

  @override
  Widget build(BuildContext context) {
    // context.l10n มาจาก lib/l10n/l10n.dart
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final usingPhoto = photo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.chooseAnimal, style: Theme.of(context).textTheme.titleSmall),
        // AppSpacing มาจาก lib/core/spacing.dart
        const SizedBox(height: AppSpacing.sm),
        // แถวตัวละครเลื่อนแนวนอน: ตัวที่เลือกมีกรอบสีหลัก + ป้ายเครื่องหมายถูก (ไม่ใช้สีอย่างเดียว)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final preset in AvatarPreset.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: _PresetChoice(
                    preset: preset,
                    selected: !usingPhoto && preset == selected,
                    onTap: () => onPreset(preset),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.useMyPhoto, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (usingPhoto)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 3, color: scheme.primary),
                ),
                child: UserAvatar(preset: selected, photo: photo, radius: 28),
              ),
            OutlinedButton.icon(
              onPressed: () => _pick(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.fromGallery),
            ),
            Tooltip(
              message: l10n.cameraHint,
              child: OutlinedButton.icon(
                onPressed: () => _pick(context, ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.takePhoto),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetChoice extends StatelessWidget {
  const _PresetChoice({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AvatarPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: preset.name,
      excludeSemantics: true,
      onTap: onTap,
      // SelectedScale มาจาก lib/widgets/motion_widgets.dart
      child: SelectedScale(
        selected: selected,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                // AppMotion มาจาก lib/core/motion.dart
                duration: AppMotion.reduced(context)
                    ? Duration.zero
                    : AppMotion.select,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 3,
                    color: selected
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0),
                  ),
                ),
                child: UserAvatar(preset: preset, radius: 28),
              ),
              if (selected)
                PositionedDirectional(
                  end: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                    child: Icon(Icons.check, size: 14, color: scheme.onPrimary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// เลือกรูปด้วย image_picker แล้วให้ย่อก่อนส่งกลับ: ไม่เกิน 300x300 px, คุณภาพ JPEG 65%
/// คืนค่า null ถ้าผู้ใช้กดยกเลิก หรือเปิดรูปไม่ได้ (แจ้ง error ให้แล้ว)
Future<Uint8List?> pickProfilePhoto(
  BuildContext context,
  ImageSource source,
) async {
  try {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 65,
    );
    return await file?.readAsBytes();
  } catch (_) {
    // เช่น ผู้ใช้ไม่อนุญาตให้เข้าถึงรูป/กล้อง หรือเครื่องไม่มีกล้อง (Simulator)
    if (context.mounted) {
      // showMessage มาจาก lib/widgets/ui_helpers.dart
      showMessage(context, context.l10n.photoError, isError: true);
    }
    return null;
  }
}
