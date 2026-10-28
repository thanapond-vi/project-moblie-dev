import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import 'settings_service.dart';

/// โปรไฟล์ผู้ใช้: ชื่อเล่น + รูปโปรไฟล์ → เก็บที่ Firestore `users/{uid}`
///
/// รูปโปรไฟล์มี 2 แบบ (ใช้แบบใดแบบหนึ่ง):
/// - ตัวละครสัตว์ 5 แบบ: เก็บแค่ id ใน `avatarPresetId` (ภาพอยู่ในแอป)
/// - รูปของผู้ใช้เอง: ย่อเหลือ 300x300 แล้วเก็บเป็น base64 ใน `avatarBase64`
///   เขียนทับ field เดิมทุกครั้ง จึงมีรูปได้แค่ 1 รูปต่อบัญชี ไม่มีไฟล์ค้าง
///   (ไม่ใช้ Firebase Storage เพราะโปรเจกต์ใหม่ต้องใช้แผนเสียเงิน Blaze)
///
/// ชื่อเล่นและ id ตัวละคร cache ไว้ใน SharedPreferences ด้วย (เปิดแอปแล้วเห็นทันที ไม่ต้องรอเน็ต)
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final ValueNotifier<UserProfile?> current = ValueNotifier(null);

  /// true = ผู้ใช้ใหม่ที่ยังไม่มีเอกสารโปรไฟล์ → หน้าแรกจะเปิดหน้าตั้งค่าเริ่มต้นให้
  final ValueNotifier<bool> needsSetup = ValueNotifier(false);

  User? _user;

  static const _timeout = Duration(seconds: 15);

  /// Firestore จำกัดเอกสารละ 1 MB: รับไฟล์ไม่เกิน 500 KB (base64 ใหญ่ขึ้น ~1/3 ≈ 670 KB ยังไม่เกิน)
  /// ปกติรูป 300x300 คุณภาพ 65 ได้แค่ราว 20–40 KB
  static const _maxAvatarBytes = 500 * 1024;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('users').doc(_user!.uid);

  String get _cacheKey => 'profile_${_user!.uid}';

  /// ชื่อเล่นตั้งต้น = displayName ของ Firebase Auth หรือส่วนหน้า @ ของอีเมล
  String defaultNickname(User user) {
    final name = user.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final local = (user.email ?? '').split('@').first;
    return local.length >= 2 ? local : 'Reader';
  }

  /// เอกสารรุ่นเก่าใช้ field `selectedCoverId` (ตอนที่ภาพสัตว์เป็นปก) → อ่านเป็นตัวละครแทน
  AvatarPreset _presetFrom(Map<String, dynamic>? data) => AvatarPreset.fromId(
    (data?['avatarPresetId'] ?? data?['selectedCoverId']) as String?,
  );

  /// โหลดโปรไฟล์ (เรียกตอนเข้าหน้า Home): แสดงค่าจาก cache ก่อน แล้วอัปเดตจาก Firestore
  Future<void> load(User user) async {
    _user = user;
    needsSetup.value = false;
    final prefs = await SettingsService.instance.prefs;
    // ระหว่างรอ ผู้ใช้ logout/สลับบัญชีไปแล้ว
    if (_user?.uid != user.uid) return;

    // 1) จาก cache ในเครื่อง (เร็ว ไม่ต้องใช้เน็ต)
    try {
      final raw = prefs.getString(_cacheKey);
      final cached = raw == null
          ? null
          : jsonDecode(raw) as Map<String, dynamic>;
      current.value = UserProfile(
        nickname: cached?['nickname'] as String? ?? defaultNickname(user),
        preset: _presetFrom(cached),
      );
    } catch (_) {
      current.value = UserProfile(
        nickname: defaultNickname(user),
        preset: AvatarPreset.cat,
      );
    }

    // 2) จาก Firestore (ข้อมูลจริงล่าสุด รวมรูปของผู้ใช้เอง)
    try {
      final snap = await _doc.get().timeout(_timeout);
      if (_user?.uid != user.uid) return;
      final data = snap.data();
      if (data == null) {
        // ยังไม่มีเอกสาร = เพิ่งสมัคร → ให้ไปตั้งค่าเริ่มต้นก่อน
        needsSetup.value = true;
        return;
      }
      current.value = UserProfile(
        nickname: data['nickname'] as String? ?? defaultNickname(user),
        preset: _presetFrom(data),
        avatarBase64: data['avatarBase64'] as String?,
      );
      await _writeCache();
    } catch (_) {
      // ออฟไลน์/ไม่มีสิทธิ์: ใช้ค่าจาก cache ต่อไป แอปยังใช้ได้
    }
  }

  /// บันทึกจากหน้าตั้งค่าเริ่มต้น (ครั้งแรกหลังสมัคร): ชื่อเล่น + ตัวละคร หรือรูปของตัวเอง
  Future<void> completeSetup({
    required String nickname,
    required AvatarPreset preset,
    Uint8List? photo,
  }) async {
    final name = nickname.trim();
    final encoded = photo == null ? null : _encode(photo);
    final uid = _user?.uid;
    await _run(
      () => _doc.set(
        _fields({
          'nickname': name,
          'avatarPresetId': preset.id,
          // ?encoded = ใส่ field นี้เฉพาะเมื่อมีรูป (null = ไม่ส่ง field ไปเลย)
          'avatarBase64': ?encoded,
        }),
        SetOptions(merge: true),
      ),
    );
    if (!_isStill(uid)) return;
    current.value = UserProfile(
      nickname: name,
      preset: preset,
      avatarBase64: encoded,
    );
    needsSetup.value = false;
    await _writeCache();
    await _syncDisplayName(name);
  }

  Future<void> updateNickname(String nickname) async {
    final name = nickname.trim();
    final uid = _user?.uid;
    await _run(
      () => _doc.set(_fields({'nickname': name}), SetOptions(merge: true)),
    );
    // Firestore คือแหล่งข้อมูลหลัก: บันทึกสำเร็จแล้วอัปเดตจอทันที
    if (!_isStill(uid)) return;
    current.value = current.value?.copyWith(nickname: name);
    await _writeCache();
    await _syncDisplayName(name);
  }

  /// เลือกตัวละคร = เลิกใช้รูปของตัวเอง (ลบ avatarBase64 ทิ้ง) เพราะใช้ได้ทีละแบบ
  Future<void> usePreset(AvatarPreset preset) async {
    final uid = _user?.uid;
    await _run(
      () => _doc.set(
        _fields({
          'avatarPresetId': preset.id,
          'avatarBase64': FieldValue.delete(),
        }),
        SetOptions(merge: true),
      ),
    );
    if (!_isStill(uid)) return;
    current.value = current.value?.copyWith(preset: preset, clearAvatar: true);
    await _writeCache();
  }

  /// bytes = รูปที่ image_picker ย่อมาแล้ว (300x300, คุณภาพ 65)
  Future<void> usePhoto(Uint8List bytes) async {
    final encoded = _encode(bytes);
    final uid = _user?.uid;
    await _run(
      () => _doc.set(
        _fields({'avatarBase64': encoded}), // เขียนทับรูปเดิม
        SetOptions(merge: true),
      ),
    );
    if (_isStill(uid)) {
      current.value = current.value?.copyWith(avatarBase64: encoded);
    }
  }

  void detach() {
    _user = null;
    current.value = null;
    needsSetup.value = false;
  }

  String _encode(Uint8List bytes) {
    if (bytes.length > _maxAvatarBytes) {
      throw AppException(tr.errImageTooLarge);
    }
    return base64Encode(bytes);
  }

  /// sync ชื่อไป Firebase Auth แบบ "ทำได้ก็ดี" ถ้าพลาด (เช่น เน็ตหลุด) ไม่ต้องแจ้ง error
  /// เพราะชื่อใน Firestore ถูกต้องแล้ว และครั้งหน้าที่แก้ชื่อจะ sync ใหม่
  Future<void> _syncDisplayName(String name) async {
    try {
      await _user?.updateDisplayName(name).timeout(_timeout);
    } catch (_) {}
  }

  /// ยังเป็นผู้ใช้คนเดิมอยู่ไหม (หลัง await อาจมีการ logout/สลับบัญชี)
  bool _isStill(String? uid) => uid != null && _user?.uid == uid;

  /// ทุกครั้งที่เขียน แนบอีเมลและเวลาแก้ไขไปด้วย (merge: true = แก้เฉพาะ field ที่ส่ง)
  Map<String, Object?> _fields(Map<String, Object?> data) => {
    ...data,
    'email': _user!.email,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Future<void> _writeCache() async {
    final profile = current.value;
    if (profile == null || _user == null) return;
    try {
      final prefs = await SettingsService.instance.prefs;
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'nickname': profile.nickname,
          'avatarPresetId': profile.preset.id,
        }),
      );
    } catch (_) {}
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_user == null) throw AppException(tr.errLoginAgain);
    try {
      await action().timeout(_timeout);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw AppException(tr.errProfilePermission);
      }
      throw AppException(tr.errProfileSave(e.code));
    } on TimeoutException {
      throw AppException(tr.errTimeout);
    }
  }
}
