import 'package:flutter_test/flutter_test.dart';
import 'package:keep/core/validators.dart';

// ทดสอบ Form Validation (ไม่ต้องใช้ Firebase จึงรันได้ด้วย `flutter test`)
void main() {
  group('Validators.email', () {
    test('ว่าง = ไม่ผ่าน', () => expect(Validators.email(''), isNotNull));
    test(
      'ไม่มี @ = ไม่ผ่าน',
      () => expect(Validators.email('abc.com'), isNotNull),
    );
    test('ถูกรูปแบบ = ผ่าน', () => expect(Validators.email('a@b.co'), isNull));
  });

  group('Validators.password', () {
    test(
      'สั้นกว่า 6 = ไม่ผ่าน',
      () => expect(Validators.password('12345'), isNotNull),
    );
    test(
      '6 ตัวขึ้นไป = ผ่าน',
      () => expect(Validators.password('123456'), isNull),
    );
  });

  test('confirmPassword ต้องตรงกัน', () {
    expect(Validators.confirmPassword('abc123', 'abc124'), isNotNull);
    expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
  });

  test('summary ต้องยาวอย่างน้อย 50 ตัวอักษร', () {
    expect(Validators.summary('สั้น'), isNotNull);
    expect(Validators.summary('ก' * 50), isNull);
  });

  group('Validators.nickname (2–20 ตัวอักษร)', () {
    test('ว่าง = ไม่ผ่าน', () => expect(Validators.nickname('  '), isNotNull));
    test('1 ตัว = ไม่ผ่าน', () => expect(Validators.nickname('ก'), isNotNull));
    test(
      '"ภู" (ภ + สระอู) = 2 ตัว ผ่าน',
      () => expect(Validators.nickname('ภู'), isNull),
    );
    test(
      '21 ตัว = ไม่ผ่าน',
      () => expect(Validators.nickname('a' * 21), isNotNull),
    );
  });
}
