import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_exception.dart';
import '../l10n/l10n.dart';

/// ห่อ FirebaseAuth ไว้ เพื่อให้หน้าจอไม่ต้องรู้รายละเอียดของ Firebase
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static const _timeout = Duration(seconds: 20);

  User? get currentUser => _auth.currentUser;

  /// Stream ที่ปล่อยค่าทุกครั้งที่สถานะล็อกอินเปลี่ยน (ล็อกอิน/ออก/เปิดแอปใหม่)
  /// AuthGate ใน main.dart ฟัง stream นี้เพื่อเลือกหน้าแรก
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn(String email, String password) => _run(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<void> register(String email, String password) => _run(
    () => _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<void> signOut() => _run(_auth.signOut);

  // ---------- Google ----------
  // ใช้ระบบเข้าสู่ระบบของ Firebase เอง (เปิดหน้า Google ในหน้าต่างระบบที่ปลอดภัย)
  // ไม่ใช้แพ็กเกจ google_sign_in เพราะไลบรารี iOS ของมันเข้ากับ Firebase iOS 13 ไม่ได้

  /// ผู้ใช้ปิดหน้าต่าง Google เอง (iOS สะกด cancelled / Android สะกด canceled)
  static const _canceledCodes = {
    'web-context-cancelled',
    'web-context-canceled',
    'canceled',
    'cancelled',
  };

  /// ล็อกอินบัญชีเดิมของ Firebase ด้วย Google หรือสร้างบัญชีใหม่ถ้ายังไม่เคยมี
  /// คืน false ถ้าผู้ใช้ปิดหน้าต่าง Google เอง (ไม่ใช่ error)
  Future<bool> signInWithGoogle() =>
      _google(() => _auth.signInWithProvider(GoogleAuthProvider()));

  /// ไม่มี timeout: ผู้ใช้อาจใช้เวลาเลือกบัญชีในหน้าต่าง Google นานเท่าไรก็ได้
  Future<bool> _google(Future<Object?> Function() action) async {
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      if (_canceledCodes.contains(e.code)) return false;
      // AppException มาจาก lib/core/app_exception.dart
      throw AppException(_messageFor(e.code));
    } catch (_) {
      // context.l10n มาจาก lib/l10n/l10n.dart
      throw AppException(tr.errGoogleFailed);
    }
  }

  /// วิธีล็อกอินของบัญชีปัจจุบัน (ใช้เลือกวิธียืนยันตัวตนก่อนลบบัญชี)
  bool get usesPassword => _providers.contains(EmailAuthProvider.PROVIDER_ID);
  bool get usesGoogle => _providers.contains(GoogleAuthProvider.PROVIDER_ID);

  Set<String> get _providers => {
    for (final info in _auth.currentUser?.providerData ?? const <UserInfo>[])
      info.providerId,
  };

  /// ยืนยันตัวตนอีกครั้ง (Firebase บังคับก่อนทำเรื่องสำคัญ เช่น ลบบัญชี)
  /// บัญชีรหัสผ่าน = ใช้ [password], บัญชี Google = ให้เลือกบัญชี Google อีกครั้ง
  /// คืน false ถ้าผู้ใช้ยกเลิกหน้าต่าง Google
  Future<bool> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw AppException(tr.errLoginAgain);
    if (password != null && usesPassword) {
      await _run(
        () => user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: user.email ?? '',
            password: password,
          ),
        ),
      );
      return true;
    }
    return _google(() => user.reauthenticateWithProvider(GoogleAuthProvider()));
  }

  /// ลบบัญชี Firebase Auth ของผู้ใช้ปัจจุบัน (ต้อง reauthenticate มาก่อนไม่นาน)
  Future<void> deleteCurrentUser() =>
      _run(() async => _auth.currentUser?.delete());

  /// ส่งอีเมลตั้งรหัสผ่านใหม่ (Firebase ส่งให้เอง)
  /// ถ้าเปิดการป้องกันการเดาอีเมลไว้ Firebase จะตอบสำเร็จแม้ไม่มีบัญชีนี้ หน้าจอจึงต้องพูดแบบกลางๆ
  Future<void> sendPasswordReset(String email) => _run(() async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // ไม่มีบัญชีนี้ = ตอบเหมือนส่งสำเร็จ ไม่บอกคนอื่นว่าอีเมลไหนมีบัญชี
      if (e.code != 'user-not-found') rethrow;
    }
    return null;
  });

  /// รูปแบบเดียวกันทุก method: await + timeout + แปลง error เป็น AppException
  Future<void> _run(Future<Object?> Function() action) async {
    try {
      await action().timeout(_timeout);
    } on FirebaseAuthException catch (e) {
      throw AppException(_messageFor(e.code));
    } on TimeoutException {
      throw AppException(tr.errTimeout);
    } catch (_) {
      throw AppException(tr.errGeneric);
    }
  }

  /// แปลงรหัส error ของ Firebase เป็นข้อความตามภาษาแอป
  static String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return tr.vEmailInvalid;
      case 'user-disabled':
        return tr.errUserDisabled;
      // Firebase รุ่นใหม่รวม user-not-found / wrong-password เป็น invalid-credential
      // เพื่อไม่ให้คนอื่นเดาได้ว่าอีเมลไหนมีบัญชี
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return tr.errWrongCredentials;
      case 'email-already-in-use':
        return tr.errEmailInUse;
      case 'weak-password':
        return tr.errWeakPassword;
      case 'too-many-requests':
        return tr.errTooManyRequests;
      case 'network-request-failed':
        return tr.errNoInternet;
      // ยืนยันตัวตนนานเกินไปแล้ว (ปกติไม่เกิด เพราะเรียก reauthenticate ก่อนลบทันที)
      case 'requires-recent-login':
        return tr.errLoginAgain;
      // อีเมลเดียวกันสมัครด้วยรหัสผ่านไว้แล้ว (Firebase ให้ 1 อีเมลต่อ 1 บัญชี)
      case 'account-exists-with-different-credential':
        return tr.errAccountOtherProvider;
      // ยังไม่ได้เปิด Google ใน Firebase Console / ตั้งค่า URL scheme ของแอปไม่ครบ
      case 'invalid-credential-or-provider-id':
      case 'invalid-provider-id':
      case 'missing-or-invalid-nonce':
        return tr.errGoogleSetup;
      case 'operation-not-allowed':
        return tr.errAuthNotEnabled;
      default:
        return tr.errGenericCode(code);
    }
  }
}
