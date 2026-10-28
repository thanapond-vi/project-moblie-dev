import 'dart:convert';
import 'dart:typed_data';

/// รูปโปรไฟล์สำเร็จรูป 5 แบบ (ตัวละครสัตว์นักอ่าน) เลือกได้ตอนตั้งค่าครั้งแรกหรือใน Settings
/// เก็บใน Firestore แค่ id (field `avatarPresetId`) ภาพอยู่ในแอปที่ assets/avatars/
/// ภาพตัดเป็นสี่เหลี่ยมจัตุรัสโดยให้หน้าสัตว์อยู่กลาง จึงแสดงเป็นวงกลมได้พอดี
enum AvatarPreset {
  cat('cover_cat', 'Cozy Cat'),
  owl('cover_owl', 'Night Owl'),
  fox('cover_fox', 'Forest Fox'),
  capybara('cover_capybara', 'Zen Capybara'),
  bunny('cover_bunny', 'Starlight Bunny');

  const AvatarPreset(this.id, this.name);

  final String id;
  final String name;

  String get asset => 'assets/avatars/$id.png';

  static AvatarPreset fromId(String? id) => AvatarPreset.values.firstWhere(
    (a) => a.id == id,
    orElse: () => AvatarPreset.cat,
  );
}

/// ข้อมูลโปรไฟล์ = เอกสาร Firestore `users/{uid}`
class UserProfile {
  UserProfile({required this.nickname, required this.preset, this.avatarBase64})
    : avatarBytes = _decode(avatarBase64);

  final String nickname;

  /// ตัวละครที่เลือก (ใช้แสดงเมื่อไม่ได้อัปโหลดรูปของตัวเอง)
  final AvatarPreset preset;

  /// รูปของผู้ใช้เองที่ย่อแล้ว เข้ารหัสเป็น base64 (null = ใช้รูปตัวละคร preset)
  final String? avatarBase64;

  /// ถอดรหัส base64 ไว้ครั้งเดียวตอนสร้าง object ไม่ต้องถอดใหม่ทุกครั้งที่วาดหน้าจอ
  final Uint8List? avatarBytes;

  static Uint8List? _decode(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      return base64Decode(data);
    } catch (_) {
      return null; // ข้อมูลเสีย → ใช้รูปตัวละครที่เลือกไว้แทน
    }
  }

  UserProfile copyWith({
    String? nickname,
    AvatarPreset? preset,
    String? avatarBase64,
    bool clearAvatar = false,
  }) => UserProfile(
    nickname: nickname ?? this.nickname,
    preset: preset ?? this.preset,
    avatarBase64: clearAvatar ? null : (avatarBase64 ?? this.avatarBase64),
  );
}
