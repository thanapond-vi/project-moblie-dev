import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/app_restarter.dart';
import '../core/validators.dart';
import '../l10n/l10n.dart';
import '../models/content_language.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/sources/article_source.dart';
import '../widgets/avatar_widgets.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/motion_widgets.dart';
import '../core/spacing.dart';

/// หน้าจอ 5: โปรไฟล์ + Settings (SharedPreferences) + Logout
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _settings = SettingsService.instance;
  bool _signingOut = false;

  Future<void> _logout() async {
    final l10n = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l10n.logoutTitle,
      message: l10n.logoutMessage,
      confirmLabel: l10n.logout,
    );
    if (!ok || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await AuthService().signOut();
      // ลืมข้อมูลของคนนี้ในหน่วยความจำ (เซสชันยังเก็บในเครื่อง ล็อกอินกลับมาก็อ่านต่อได้)
      SessionService.instance.detach();
      ProfileService.instance.detach();
      // ปิดทุกหน้าที่ซ้อนอยู่ให้เหลือหน้าแรก (AuthGate) ซึ่งจะแสดง AuthScreen เอง
      // ผู้ใช้จึงกดย้อนกลับไปหน้าที่ต้องล็อกอินไม่ได้
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _signingOut = false);
        showMessage(context, e.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: staggered([
          _ProfileHeader(user: widget.user),
          const SizedBox(height: 24),
          _SectionTitle(l10n.languageSection),
          const _LanguageSettings(),
          const SizedBox(height: 24),
          _SectionTitle(l10n.sourcesSection),
          const _SourceSettings(),
          const SizedBox(height: 24),
          _SectionTitle(l10n.readingSection),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.readingTimePerRound),
                  const SizedBox(height: 12),
                  // ValueListenableBuilder: rebuild เฉพาะส่วนนี้เมื่อค่าใน SettingsService เปลี่ยน
                  ValueListenableBuilder<int>(
                    valueListenable: _settings.timerMinutes,
                    builder: (context, minutes, _) => SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        segments: [
                          for (final m in SettingsService.timerOptions)
                            ButtonSegment(
                              value: m,
                              label: Text(l10n.minutesValue(m)),
                            ),
                        ],
                        selected: {minutes},
                        onSelectionChanged: (s) =>
                            _settings.setTimerMinutes(s.first),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(l10n.displaySection),
          Card(
            child: ValueListenableBuilder<bool>(
              valueListenable: _settings.isDarkMode,
              builder: (context, isDark, _) => SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: Text(l10n.darkMode),
                value: isDark,
                onChanged: _settings.setDarkMode,
              ),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            onPressed: _signingOut ? null : _logout,
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
          ),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// ส่วนหัวโปรไฟล์: รูปโปรไฟล์ (แตะเพื่อเปลี่ยน) + ชื่อเล่น (แก้ได้) + อีเมล
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User user;

  Future<void> _changeAvatar(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
          ),
          // ฟังโปรไฟล์ในแผ่นด้วย: เลือกแล้วกรอบที่เลือกขยับตามทันที
          child: ValueListenableBuilder<UserProfile?>(
            valueListenable: ProfileService.instance.current,
            builder: (context, profile, _) => AvatarPicker(
              selected: profile?.preset ?? AvatarPreset.cat,
              photo: profile?.avatarBytes,
              onPreset: (preset) => _save(
                context,
                () => ProfileService.instance.usePreset(preset),
              ),
              onPhoto: (bytes) => _save(
                context,
                () => ProfileService.instance.usePhoto(bytes),
                success: context.l10n.photoUpdated(bytes.length ~/ 1024),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    Future<void> Function() action, {
    String? success,
  }) async {
    try {
      await action();
      if (success != null && context.mounted) showMessage(context, success);
    } on AppException catch (e) {
      if (context.mounted) showMessage(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: ProfileService.instance.current,
      builder: (context, profile, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Tooltip(
                message: l10n.changePhoto,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _changeAvatar(context),
                  child: Stack(
                    children: [
                      UserAvatar.of(profile, radius: 40),
                      PositionedDirectional(
                        end: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(
                            Icons.photo_camera,
                            size: 14,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.nickname ?? '...',
                      style: theme.textTheme.titleLarge,
                    ),
                    EmailText(
                      user.email ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.editNickname,
                icon: const Icon(Icons.edit_outlined),
                onPressed: profile == null
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            _NicknameDialog(initial: profile.nickname),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// กล่องแก้ชื่อเล่น: มี Form + Validation (ต้องกรอก, 2–20 ตัวอักษร)
class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.initial});

  final String initial;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ProfileService.instance.updateNickname(_controller.text);
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.editNickname),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          enabled: !_saving,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: l10n.nickname,
            prefixIcon: const Icon(Icons.badge_outlined),
            errorText: _error, // error จาก Firestore (เช่น ไม่มีเน็ต)
          ),
          validator: Validators.nickname,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}

/// ภาษา 3 ค่า (แอป / บทความที่สุ่ม / เสียง TTS) เลือกให้ครบแล้วกด "ยืนยันภาษา"
/// → ถามว่าจะรีสตาร์ตแอปเลยไหม: ใช่ = ใช้ภาษาใหม่ทันที, ไว้ทีหลัง = ใช้ภาษาเดิมจนกว่าจะเปิดแอปใหม่
class _LanguageSettings extends StatefulWidget {
  const _LanguageSettings();

  @override
  State<_LanguageSettings> createState() => _LanguageSettingsState();
}

class _LanguageSettingsState extends State<_LanguageSettings> {
  final _settings = SettingsService.instance;

  late ContentLanguage _app;
  late ContentLanguage _article;
  late ContentLanguage? _tts;

  /// ค่าที่จะมีผลหลังรีสตาร์ต: ถ้ามีค่าค้าง (เลือก "ไว้ทีหลัง") ใช้ค่านั้น ไม่งั้นใช้ค่าปัจจุบัน
  PendingLanguages get _effective =>
      _settings.pendingLanguages.value ??
      (
        app: _settings.appLanguage.value,
        article: _settings.articleLanguage.value,
        tts: _settings.ttsLanguage.value,
      );

  bool get _changed {
    final e = _effective;
    return _app != e.app || _article != e.article || _tts != e.tts;
  }

  @override
  void initState() {
    super.initState();
    final e = _effective;
    _app = e.app;
    _article = e.article;
    _tts = e.tts;
  }

  Future<void> _apply() async {
    final l10n = context.l10n;
    final restart = await confirmDialog(
      context,
      title: l10n.restartTitle,
      message: l10n.restartMessage,
      confirmLabel: l10n.restartNow,
      cancelLabel: l10n.restartLater,
      // แตะนอกกล่องต้องไม่นับเป็น "ไว้ทีหลัง" (ผู้ใช้ต้องเลือกเอง)
      barrierDismissible: false,
    );
    if (!mounted) return;
    await _settings.saveLanguages(
      app: _app,
      article: _article,
      tts: _tts,
      applyNow: restart,
    );
    if (!mounted) return;
    if (restart) {
      AppRestarter.restart(context); // สร้างแอปใหม่ทั้งหมดด้วยภาษาใหม่
    } else {
      showMessage(context, l10n.languageSavedForLater);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pending = _settings.pendingLanguages.value != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LanguageRow<ContentLanguage>(
              title: l10n.appLanguage,
              hint: l10n.appLanguageHint,
              options: [for (final l in ContentLanguage.values) (l, l.label)],
              selected: _app,
              onChanged: (v) => setState(() => _app = v),
            ),
            const Divider(height: 28),
            _LanguageRow<ContentLanguage>(
              title: l10n.articleLanguage,
              hint: l10n.articleLanguageHint,
              options: [for (final l in ContentLanguage.values) (l, l.label)],
              selected: _article,
              onChanged: (v) => setState(() => _article = v),
            ),
            const Divider(height: 28),
            // TTS มีตัวเลือก AUTO (= null) อ่านด้วยเสียงภาษาเดียวกับบทความ
            _LanguageRow<ContentLanguage?>(
              title: l10n.ttsLanguage,
              hint: l10n.ttsLanguageHint,
              options: [
                (null, 'AUTO'),
                for (final l in ContentLanguage.values) (l, l.label),
              ],
              selected: _tts,
              onChanged: (v) => setState(() => _tts = v),
            ),
            const SizedBox(height: 16),
            if (pending && !_changed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.languagePending,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            FilledButton.icon(
              onPressed: _changed ? _apply : null,
              icon: const Icon(Icons.check),
              label: Text(l10n.applyLanguage),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow<T> extends StatelessWidget {
  const _LanguageRow({
    required this.title,
    required this.hint,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final String hint;

  /// (ค่า, คำที่แสดง) เรียง ENG ก่อน และแสดงเป็นคำ ไม่มีธง
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodyLarge),
        Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final (value, label) in options)
                ButtonSegment(value: value, label: Text(label)),
            ],
            selected: {selected},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      ],
    );
  }
}

/// แหล่งข้อมูลบทความ: ตอนนี้มี Wikipedia + ช่องรอแหล่งข้อมูล/plugin ในอัปเดตถัดไป
class _SourceSettings extends StatelessWidget {
  const _SourceSettings();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = SettingsService.instance;
    return Card(
      child: ValueListenableBuilder<String>(
        valueListenable: settings.sourceId,
        builder: (context, selected, _) => Column(
          children: [
            for (final source in ArticleSources.all)
              ListTile(
                leading: const Icon(Icons.public),
                title: Text(source.name),
                subtitle: Text(l10n.sourceWikipediaDesc),
                trailing: Icon(
                  source.id == selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () => settings.setSource(source.id),
              ),
            const Divider(height: 1),
            ListTile(
              enabled: false,
              leading: const Icon(Icons.extension_outlined),
              title: Text(l10n.sourcesMore),
              subtitle: Text(l10n.sourcesMoreHint),
              trailing: Chip(label: Text(l10n.comingSoon)),
            ),
          ],
        ),
      ),
    );
  }
}

/// อีเมลยาว: ตัดเฉพาะส่วนหน้า @ ด้วย … ส่วนโดเมน (@gmail.com) แสดงเต็มเสมอ
/// กดค้างเพื่อดูอีเมลเต็ม และ screen reader อ่านอีเมลเต็ม
@visibleForTesting
class EmailText extends StatelessWidget {
  const EmailText(this.email, {super.key, this.style});

  final String email;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final at = email.lastIndexOf('@');
    final Widget text = at <= 0
        ? Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  email.substring(0, at),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              Text(email.substring(at), maxLines: 1, style: style),
            ],
          );
    return Tooltip(
      message: email,
      triggerMode: TooltipTriggerMode.longPress,
      child: Semantics(label: email, excludeSemantics: true, child: text),
    );
  }
}
