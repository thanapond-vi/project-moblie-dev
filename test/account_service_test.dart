import 'package:flutter_test/flutter_test.dart';
import 'package:keep/core/app_exception.dart';
import 'package:keep/services/account_service.dart';
import 'package:keep/services/auth_service.dart';

// ลบบัญชี: ต้องทำตามลำดับ และหยุดทันทีเมื่อขั้นไหนพลาด (ไม่ลบบัญชีทิ้งทั้งที่ข้อมูลยังลบไม่ครบ)
class _FakeAuth implements AuthService {
  _FakeAuth(this.steps, {this.wrongPassword = false, this.cancel = false});

  final List<String> steps;
  final bool wrongPassword;

  /// ผู้ใช้ Google กดยกเลิกหน้าต่างยืนยันตัวตน
  final bool cancel;

  @override
  Future<bool> reauthenticate({String? password}) async {
    if (wrongPassword) throw AppException('wrong password');
    if (cancel) return false;
    steps.add('reauth:${password ?? 'google'}');
    return true;
  }

  @override
  Future<void> deleteCurrentUser() async => steps.add('deleteUser');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AccountService _service(
  List<String> steps, {
  bool wrongPassword = false,
  bool remoteFails = false,
  bool cancel = false,
}) => AccountService(
  auth: _FakeAuth(steps, wrongPassword: wrongPassword, cancel: cancel),
  currentUid: () => 'u1',
  deleteRemoteData: (uid) async {
    if (remoteFails) throw AppException('permission denied');
    steps.add('remote:$uid');
  },
  clearLocalData: (uid) async => steps.add('local:$uid'),
);

void main() {
  test(
    'สำเร็จ: ยืนยันรหัส → ลบข้อมูล Firestore → ลบบัญชี → ล้างข้อมูลในเครื่อง',
    () async {
      final steps = <String>[];
      await _service(steps).deleteAccount(password: 'secret1');
      expect(steps, ['reauth:secret1', 'remote:u1', 'deleteUser', 'local:u1']);
    },
  );

  test('รหัสผ่านผิด: ไม่มีอะไรถูกลบ', () async {
    final steps = <String>[];
    await expectLater(
      _service(steps, wrongPassword: true).deleteAccount(password: 'x'),
      throwsA(isA<AppException>()),
    );
    expect(steps, isEmpty);
  });

  test(
    'ลบข้อมูลใน Firestore ไม่ได้ (เช่น กฎยังไม่อนุญาต): บัญชียังอยู่',
    () async {
      final steps = <String>[];
      await expectLater(
        _service(steps, remoteFails: true).deleteAccount(password: 'secret1'),
        throwsA(isA<AppException>()),
      );
      expect(steps, ['reauth:secret1']);
    },
  );

  test(
    'บัญชี Google: ยืนยันด้วย Google แทนรหัสผ่าน แล้วลบตามลำดับเดิม',
    () async {
      final steps = <String>[];
      expect(await _service(steps).deleteAccount(), isTrue);
      expect(steps, ['reauth:google', 'remote:u1', 'deleteUser', 'local:u1']);
    },
  );

  test('บัญชี Google กดยกเลิก: คืน false และไม่มีอะไรถูกลบ', () async {
    final steps = <String>[];
    expect(await _service(steps, cancel: true).deleteAccount(), isFalse);
    expect(steps, isEmpty);
  });
}
