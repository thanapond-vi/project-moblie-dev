import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/validators.dart';
import '../l10n/l10n.dart';
import '../models/content_language.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../widgets/avatar_widgets.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/motion_widgets.dart';
import '../core/spacing.dart';

/// หน้าตั้งค่าเริ่มต้น (เปิดครั้งแรกหลังสมัคร): เลือกสิ่งพื้นฐานที่จำเป็น
/// ชื่อเล่น, รูปโปรไฟล์ (ตัวละคร 5 แบบ หรือรูปตัวเอง), ภาษาแอป, ภาษาบทความ, เวลาอ่านต่อรอบ
///
/// ทุกค่าแก้ทีหลังได้ใน Settings ส่วนภาษา TTS ใช้ค่าเริ่มต้นไปก่อน
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.user});

  final User user;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _settings = SettingsService.instance;
  late final _nickname = TextEditingController(
    text: ProfileService.instance.defaultNickname(widget.user),
  );

  AvatarPreset _preset = AvatarPreset.cat;
  Uint8List? _photo;
  late ContentLanguage _appLanguage = _settings.appLanguage.value;
  late ContentLanguage _articleLanguage = _settings.articleLanguage.value;
  late int _minutes = _settings.timerMinutes.value;
  bool _saving = false;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      // 1) โปรไฟล์ → Firestore users/{uid}
      await ProfileService.instance.completeSetup(
        nickname: _nickname.text,
        preset: _preset,
        photo: _photo,
      );
      // 2) ค่าในเครื่อง → SharedPreferences (ภาษาใช้ทันที เพราะเพิ่งเริ่มใช้แอป)
      await _settings.setTimerMinutes(_minutes);
      await _settings.saveLanguages(
        app: _appLanguage,
        article: _articleLanguage,
        // เสียงอ่านตามภาษาบทความที่เลือก (ไม่งั้นบทความไทยจะถูกอ่านด้วยเสียงอังกฤษ)
        tts: _articleLanguage,
        applyNow: true,
      );
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, e.message, isError: true);
      }
    } catch (_) {
      // error อื่นๆ ต้องปลดล็อกปุ่มด้วย ไม่งั้นติดอยู่หน้านี้ (หน้านี้ปิดเองไม่ได้)
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, context.l10n.errGeneric, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // แสดงหน้านี้ด้วยภาษาที่กำลังเลือก (ทั้งหน้ารวม widget ลูก) ผู้ใช้เห็นผลทันทีว่าเลือกภาษาอะไร
    return Localizations.override(
      context: context,
      locale: _appLanguage.locale,
      child: Builder(builder: _build),
    );
  }

  Widget _build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // ห้ามปิดหน้านี้ด้วยปุ่มย้อนกลับ ต้องกด "เริ่มใช้งาน" (บันทึกโปรไฟล์) ก่อน
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.setupTitle),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                top: AppSpacing.xs,
                right: AppSpacing.lg,
                bottom: AppSpacing.xxl,
              ),
              children: staggered([
                Text(
                  l10n.setupSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: UserAvatar(preset: _preset, photo: _photo, radius: 48),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nickname,
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.nickname,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => Validators.nickname(v, l10n),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.setupProfilePicture,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                AvatarPicker(
                  selected: _preset,
                  photo: _photo,
                  // เลือกตัวละคร = ไม่ใช้รูปตัวเอง (ใช้ได้ทีละแบบ)
                  onPreset: (p) => setState(() {
                    _preset = p;
                    _photo = null;
                  }),
                  onPhoto: (bytes) => setState(() => _photo = bytes),
                ),
                const SizedBox(height: 24),
                Text(l10n.appLanguage, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _choice<ContentLanguage>(
                  values: ContentLanguage.values,
                  label: (l) => l.label,
                  selected: _appLanguage,
                  onChanged: (l) => setState(() => _appLanguage = l),
                ),
                const SizedBox(height: 20),
                Text(l10n.articleLanguage, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _choice<ContentLanguage>(
                  values: ContentLanguage.values,
                  label: (l) => l.label,
                  selected: _articleLanguage,
                  onChanged: (l) => setState(() => _articleLanguage = l),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.readingTimePerRound,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _choice<int>(
                  values: SettingsService.timerOptions,
                  label: l10n.minutesValue,
                  selected: _minutes,
                  onChanged: (m) => setState(() => _minutes = m),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _saving ? null : _finish,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.auto_stories),
                  label: Text(l10n.setupStart),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _choice<T>({
    required List<T> values,
    required String Function(T) label,
    required T selected,
    required ValueChanged<T> onChanged,
  }) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [
          for (final v in values)
            ButtonSegment(value: v, label: Text(label(v))),
        ],
        selected: {selected},
        onSelectionChanged: _saving ? null : (s) => onChanged(s.first),
      ),
    );
  }
}
