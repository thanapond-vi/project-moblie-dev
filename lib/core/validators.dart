import '../l10n/l10n.dart';

/// ฟังก์ชันตรวจสอบข้อมูลในฟอร์ม (Form Validation)
/// คืนค่า null = ผ่าน, คืนข้อความ = ไม่ผ่าน (TextFormField จะแสดงข้อความนี้ใต้ช่องกรอก)
/// ข้อความแปลตามภาษาของแอปผ่าน `tr`
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static const int minPasswordLength = 6;
  static const int minSummaryLength = 50;
  static const int minNicknameLength = 2;
  static const int maxNicknameLength = 20;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return tr.vEmailRequired;
    if (!_emailPattern.hasMatch(v)) return tr.vEmailInvalid;
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return tr.vPasswordRequired;
    if (v.length < minPasswordLength) {
      return tr.vPasswordMin(minPasswordLength);
    }
    return null;
  }

  /// ใช้ตอนสมัครสมาชิก: ต้องตรงกับรหัสผ่านที่กรอกไว้ก่อนหน้า
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return tr.vConfirmRequired;
    if (value != original) return tr.vPasswordMismatch;
    return null;
  }

  static String? summary(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return tr.vSummaryRequired;
    if (v.length < minSummaryLength) {
      return tr.vSummaryMin(minSummaryLength, v.length);
    }
    return null;
  }

  /// นับตามตัวอักษรที่พิมพ์ (Unicode code point ผ่าน runes) เช่น "ภู" = 2 ตัว ตรงกับที่คนไทยนับ
  /// (ถ้านับแบบกลุ่มที่มองเห็น "ภู" จะกลายเป็น 1 ตัว ชื่อเล่น 2 ตัวอักษรจะไม่ผ่าน)
  /// [l10n] ใช้ตอนหน้าจอแสดงภาษาอื่นอยู่ (หน้าตั้งค่าเริ่มต้นแสดงภาษาที่กำลังเลือก)
  static String? nickname(String? value, [AppLocalizations? l10n]) {
    final t = l10n ?? tr;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return t.vNicknameRequired;
    final count = v.runes.length;
    if (count < minNicknameLength || count > maxNicknameLength) {
      return t.vNicknameLength(minNicknameLength, maxNicknameLength);
    }
    return null;
  }
}
