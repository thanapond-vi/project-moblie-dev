import 'package:flutter_test/flutter_test.dart';
import 'package:keep/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// สวิตช์ "เสียงตอนเปิดแอป" ใน Settings
void main() {
  test('ผู้ใช้ใหม่: เปิดเสียงไว้ก่อน', () async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.load();
    expect(SettingsService.instance.launchSound.value, isTrue);
  });

  test('ปิดเสียงแล้วเปิดแอปใหม่ ยังปิดอยู่', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService.instance;
    await settings.load();
    await settings.setLaunchSound(false);
    await settings.load();
    expect(settings.launchSound.value, isFalse);
  });
}
