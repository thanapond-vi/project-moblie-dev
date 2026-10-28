import 'package:flutter/widgets.dart';

import '../models/article_tag.dart';
import '../services/settings_service.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// ข้อความหลายภาษา (English / Chinese / Thai) สร้างอัตโนมัติจากไฟล์ ARB ใน lib/l10n/arb
///
/// - ในหน้าจอ (มี BuildContext): ใช้ `context.l10n.xxx`
/// - ใน service / validator (ไม่มี BuildContext): ใช้ `tr.xxx`
///   ซึ่งดึงภาษาจากค่า "ภาษาของแอป" ใน SettingsService
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// ข้อความตามภาษาของแอปปัจจุบัน สำหรับโค้ดที่ไม่มี BuildContext
AppLocalizations get tr =>
    lookupAppLocalizations(SettingsService.instance.appLanguage.value.locale);

/// ชื่อหมวดตามภาษาของแอป
extension ArticleTagLabel on ArticleTag {
  String label(AppLocalizations l10n) => switch (this) {
    ArticleTag.technology => l10n.tagTechnology,
    ArticleTag.science => l10n.tagScience,
    ArticleTag.history => l10n.tagHistory,
    ArticleTag.biographies => l10n.tagBiographies,
    ArticleTag.culture => l10n.tagCulture,
  };
}

/// ชื่อแท็กที่ใช้แสดง: หมวดยอดฮิต → แปลตามภาษาแอป, หัวข้อที่ค้นเอง → แสดงตามที่พิมพ์
String tagLabel(String tag, AppLocalizations l10n) =>
    ArticleTag.fromId(tag)?.label(l10n) ?? tag;
