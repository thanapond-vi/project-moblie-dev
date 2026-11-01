import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/motion.dart';
import '../core/validators.dart';
import '../l10n/l10n.dart';
import '../models/content_language.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../widgets/avatar_widgets.dart';
import '../widgets/ui_helpers.dart';
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
  // SettingsService มาจาก lib/services/settings_service.dart
  final _settings = SettingsService.instance;
  late final _nickname = TextEditingController(
    // ProfileService มาจาก lib/services/profile_service.dart
    text: ProfileService.instance.defaultNickname(widget.user),
  );

  // AvatarPreset มาจาก lib/models/user_profile.dart
  AvatarPreset _preset = AvatarPreset.cat;
  Uint8List? _photo;
  // ContentLanguage มาจาก lib/models/content_language.dart
  late ContentLanguage _appLanguage = _settings.appLanguage.value;
  late ContentLanguage _articleLanguage = _settings.articleLanguage.value;
  late int _minutes = _settings.timerMinutes.value;
  bool _saving = false;

  /// 0 = ขั้นโปรไฟล์ (ชื่อเล่น + รูป), 1 = ขั้นการอ่าน (ภาษา + เวลาต่อรอบ)
  int _step = 0;
  static const _steps = 2;

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  /// ชื่อเล่นถูกตรวจแล้วตอนกด "ถัดไป" (ขั้นนี้ไม่มีช่องชื่อเล่นให้ตรวจซ้ำ)
  Future<void> _finish() async {
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
      // AppException มาจาก lib/core/app_exception.dart
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        // showMessage มาจาก lib/widgets/ui_helpers.dart
        showMessage(context, e.message, isError: true);
      }
    } catch (_) {
      // error อื่นๆ ต้องปลดล็อกปุ่มด้วย ไม่งั้นติดอยู่หน้านี้ (หน้านี้ปิดเองไม่ได้)
      if (mounted) {
        setState(() => _saving = false);
        // context.l10n มาจาก lib/l10n/l10n.dart
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
    final l10n = context.l10n;

    // ห้ามปิดหน้านี้ด้วยปุ่มย้อนกลับ ต้องกด "เริ่มใช้งาน" (บันทึกโปรไฟล์) ก่อน
    // ขั้นที่ 2: ปุ่มย้อนกลับของเครื่อง = กลับไปขั้นที่ 1
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0 && !_saving) setState(() => _step = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.setupTitle),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                // AppSpacing มาจาก lib/core/spacing.dart
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _StepBar(step: _step, total: _steps),
              ),
              Expanded(
                // Form ครอบทั้งสองขั้น (ไม่อยู่ในขั้นที่ 1): ระหว่างเปลี่ยนขั้นจะมีขั้นที่ 1 สองชุดซ้อนกันได้
                // ถ้า Form อยู่ข้างใน GlobalKey จะซ้ำกันแล้วแอปแครช
                child: Form(
                  key: _formKey,
                  // เปลี่ยนขั้นแบบ fade + เลื่อนสั้นๆ (ปิดเมื่อเปิด Reduce Motion)
                  child: AnimatedSwitcher(
                    // AppMotion มาจาก lib/core/motion.dart
                    duration: AppMotion.reduced(context)
                        ? Duration.zero
                        : AppMotion.page,
                    switchInCurve: AppMotion.pageEnter,
                    switchOutCurve: AppMotion.pageEnter,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: AppMotion.pageSlideFrom,
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _step == 0
                        ? _profileStep(context)
                        : _readingStep(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListView _stepList(String key, List<Widget> children) => ListView(
    key: ValueKey(key),
    padding: const EdgeInsets.only(
      left: AppSpacing.lg,
      top: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: AppSpacing.xxl,
    ),
    children: children,
  );

  /// ขั้นที่ 1: ชื่อเล่น + รูปโปรไฟล์
  Widget _profileStep(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return _stepList('profile', [
      Text(l10n.setupStep1Title, style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        l10n.setupSubtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Center(
        // UserAvatar มาจาก lib/widgets/avatar_widgets.dart
        child: UserAvatar(preset: _preset, photo: _photo, radius: 48),
      ),
      const SizedBox(height: AppSpacing.xl),
      TextFormField(
        controller: _nickname,
        enabled: !_saving,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _next(),
        decoration: InputDecoration(
          labelText: l10n.nickname,
          prefixIcon: const Icon(Icons.badge_outlined),
        ),
        // Validators มาจาก lib/core/validators.dart
        validator: (v) => Validators.nickname(v, l10n),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(l10n.setupProfilePicture, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      // AvatarPicker มาจาก lib/widgets/avatar_widgets.dart
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
      const SizedBox(height: AppSpacing.xxl),
      FilledButton.icon(
        onPressed: _next,
        icon: const Icon(Icons.arrow_forward),
        label: Text(l10n.next),
      ),
    ]);
  }

  /// ขั้นที่ 2: ภาษาแอป + ภาษาบทความ + เวลาอ่านต่อรอบ
  Widget _readingStep(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return _stepList('reading', [
      Text(l10n.setupStep2Title, style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.xl),
      Text(l10n.appLanguage, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      _choice<ContentLanguage>(
        values: ContentLanguage.values,
        label: (l) => l.label,
        selected: _appLanguage,
        onChanged: (l) => setState(() => _appLanguage = l),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.articleLanguage, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      _choice<ContentLanguage>(
        values: ContentLanguage.values,
        label: (l) => l.label,
        selected: _articleLanguage,
        onChanged: (l) => setState(() => _articleLanguage = l),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.readingTimePerRound, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      _choice<int>(
        values: SettingsService.timerOptions,
        label: l10n.minutesValue,
        selected: _minutes,
        onChanged: (m) => setState(() => _minutes = m),
      ),
      const SizedBox(height: AppSpacing.xxl),
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
      const SizedBox(height: AppSpacing.xs),
      TextButton.icon(
        onPressed: _saving ? null : () => setState(() => _step = 0),
        icon: const Icon(Icons.arrow_back),
        label: Text(l10n.back),
      ),
    ]);
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

/// แถบขั้นตอน: แท่งเท่าจำนวนขั้น (ขั้นที่ผ่าน/อยู่ = สีหลัก) + "ขั้นที่ 1 จาก 2"
class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = context.l10n.stepOf(step + 1, total);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.reduced(context)
                        ? Duration.zero
                        : AppMotion.select,
                    height: 4,
                    decoration: ShapeDecoration(
                      color: i <= step
                          ? scheme.primary
                          : scheme.surfaceContainerHigh,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
