import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  /// สร้างจากโปรไฟล์ (null = ยังโหลดไม่เสร็จ แสดงตัวละครเริ่มต้นไปก่อน)
  factory UserAvatar.of(UserProfile? profile, {double radius = 24}) =>
      UserAvatar(
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
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final usingPhoto = photo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.chooseAnimal, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final preset in AvatarPreset.values)
              SelectedScale(
                selected: !usingPhoto && preset == selected,
                child: Tooltip(
                  message: preset.name,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onPreset(preset),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 3,
                          color: !usingPhoto && preset == selected
                              ? scheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: UserAvatar(preset: preset, radius: 28),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.useMyPhoto, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
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
      showMessage(context, context.l10n.photoError, isError: true);
    }
    return null;
  }
}
