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
      case 'operation-not-allowed':
        return tr.errAuthNotEnabled;
      default:
        return tr.errGenericCode(code);
    }
  }
}
