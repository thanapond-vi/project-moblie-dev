import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/app_exception.dart';
import '../core/app_restarter.dart';
import '../core/validators.dart';
import '../l10n/l10n.dart';
import '../models/content_language.dart';
import '../models/reading_stats.dart';
import '../models/review_schedule.dart';
import '../models/study_log.dart';
import '../models/user_profile.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../services/bookmark_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/sources/article_source.dart';
import '../services/study_log_repository.dart';
import '../widgets/avatar_widgets.dart';
import '../widgets/keep_logo.dart';
import '../widgets/stat_tile.dart';
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
  // SettingsService มาจาก lib/services/settings_service.dart
  final _settings = SettingsService.instance;
  bool _signingOut = false;

  // StudyLog มาจาก lib/models/study_log.dart
  // StudyLogRepository มาจาก lib/services/study_log_repository.dart
  /// ประวัติการอ่าน (ใช้นับสถิติในการ์ดโปรไฟล์) สร้าง stream ครั้งเดียว
  late final Stream<List<StudyLog>> _logs = StudyLogRepository().watchLogs(
    widget.user.uid,
  );

  Future<void> _logout() async {
    // context.l10n มาจาก lib/l10n/l10n.dart
    final l10n = context.l10n;
    // confirmDialog มาจาก lib/widgets/ui_helpers.dart
    final ok = await confirmDialog(
      context,
      title: l10n.logoutTitle,
      message: l10n.logoutMessage,
      confirmLabel: l10n.logout,
    );
    if (!ok || !mounted) return;

    setState(() => _signingOut = true);
    try {
      // AuthService มาจาก lib/services/auth_service.dart
      await AuthService().signOut();
      // ลืมข้อมูลของคนนี้ในหน่วยความจำ (เซสชันยังเก็บในเครื่อง ล็อกอินกลับมาก็อ่านต่อได้)
      // SessionService มาจาก lib/services/session_service.dart
      SessionService.instance.detach();
      // ProfileService มาจาก lib/services/profile_service.dart
      ProfileService.instance.detach();
      // BookmarkService มาจาก lib/services/bookmark_service.dart
      BookmarkService.instance.clear();
      // ปิดทุกหน้าที่ซ้อนอยู่ให้เหลือหน้าแรก (AuthGate) ซึ่งจะแสดง AuthScreen เอง
      // ผู้ใช้จึงกดย้อนกลับไปหน้าที่ต้องล็อกอินไม่ได้
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
      // AppException มาจาก lib/core/app_exception.dart
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _signingOut = false);
        // showMessage มาจาก lib/widgets/ui_helpers.dart
        showMessage(context, e.message, isError: true);
      }
    }
  }

  /// ลบบัญชี: กล่องยืนยัน (ใส่รหัสผ่าน) จะลบเองแล้วคืนค่า true เมื่อสำเร็จ
  Future<void> _deleteAccount() async {
    // จับ messenger ไว้ก่อน: หลังลบแล้วหน้านี้ถูกปิด context จะใช้ไม่ได้
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.accountDeleted;
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (deleted != true || !mounted) return;
    // บัญชีหายแล้ว → AuthGate เห็นว่าไม่มีผู้ใช้ แล้วแสดงหน้า login เอง
    Navigator.popUntil(context, (route) => route.isFirst);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(
          // AppSpacing มาจาก lib/core/spacing.dart
          left: AppSpacing.md,
          top: AppSpacing.xs,
          right: AppSpacing.md,
          bottom: AppSpacing.xxl,
        ),
        // staggered มาจาก lib/widgets/motion_widgets.dart
        children: staggered([
          StreamBuilder<List<StudyLog>>(
            stream: _logs,
            builder: (context, snapshot) => _ProfileHeader(
              user: widget.user,
              // ยังโหลดไม่เสร็จ/โหลดไม่ได้ = ไม่มีสถิติ (การ์ดแสดงขีดแทนตัวเลข)
              stats: snapshot.hasData
                  // ReadingStats มาจาก lib/models/reading_stats.dart
                  ? ReadingStats.from(snapshot.data!)
                  : null,
              reviewSuccess: snapshot.hasData
                  // ReviewSchedule มาจาก lib/models/review_schedule.dart
                  ? ReviewSchedule.successRate(snapshot.data!)
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(l10n.languageSection),
          const _LanguageSettings(),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(l10n.sourcesSection),
          const _SourceSettings(),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(l10n.readingSection),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.readingTimePerRound,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // ValueListenableBuilder: rebuild เฉพาะส่วนนี้เมื่อค่าใน SettingsService เปลี่ยน
                  ValueListenableBuilder<int>(
                    valueListenable: _settings.timerMinutes,
                    builder: (context, minutes, _) => SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
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
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(l10n.displaySection),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _settings.isDarkMode,
                  builder: (context, isDark, _) => SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: Text(l10n.darkMode),
                    value: isDark,
                    onChanged: _settings.setDarkMode,
                  ),
                ),
                const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                ValueListenableBuilder<bool>(
                  valueListenable: _settings.launchSound,
                  builder: (context, on, _) => SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined),
                    title: Text(l10n.launchSound),
                    subtitle: Text(l10n.launchSoundHint),
                    value: on,
                    onChanged: _settings.setLaunchSound,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
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
          const SizedBox(height: AppSpacing.xs),
          // ลบบัญชี: ปุ่มรอง (ไม่เด่นเท่า logout) แต่เป็นสีแดงให้รู้ว่าอันตราย
          TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: _signingOut ? null : _deleteAccount,
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(l10n.deleteAccount),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _VersionFooter(),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xxs,
        bottom: AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// การ์ดโปรไฟล์: รูป (แตะเพื่อเปลี่ยน) + ชื่อเล่น (แก้ได้) + สถานะ · เป็นสมาชิกตั้งแต่ + อีเมล
/// และสถิติ 3 ช่อง: บันทึกแล้ว / ทบทวนสำเร็จ % / วันติดกัน
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.stats,
    required this.reviewSuccess,
  });

  final User user;

  /// null = ประวัติยังโหลดไม่เสร็จ
  final ReadingStats? stats;

  /// อัตราทบทวนสำเร็จ % (null = ยังไม่เคยทบทวน)
  final int? reviewSuccess;

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
          // UserProfile มาจาก lib/models/user_profile.dart
          child: ValueListenableBuilder<UserProfile?>(
            valueListenable: ProfileService.instance.current,
            // AvatarPicker มาจาก lib/widgets/avatar_widgets.dart
            builder: (context, profile, _) => AvatarPicker(
              // AvatarPreset มาจาก lib/models/user_profile.dart
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
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final joined = user.metadata.creationTime;
    final status = (stats?.streakDays ?? 0) > 0
        ? l10n.statusActive
        : l10n.statusReader;
    final since = joined == null
        ? null
        : l10n.memberSince(
            DateFormat.yMMM(
              SettingsService.instance.appLanguage.value.code,
            ).format(joined),
          );
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: ProfileService.instance.current,
      builder: (context, profile, _) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // ทั้งรูป (72 px) เป็นปุ่มเปลี่ยนรูป: เป้าแตะใหญ่กว่า 48 dp
                  Tooltip(
                    message: l10n.changePhoto,
                    // ป้ายสำหรับโปรแกรมอ่านหน้าจออยู่ที่ Semantics ด้านในแล้ว ไม่ให้อ่านซ้ำ
                    excludeFromSemantics: true,
                    child: Semantics(
                      button: true,
                      label: l10n.changePhoto,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _changeAvatar(context),
                        child: Stack(
                          children: [
                            // UserAvatar มาจาก lib/widgets/avatar_widgets.dart
                            UserAvatar.of(profile, radius: 36),
                            PositionedDirectional(
                              end: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: scheme.primary,
                                child: Icon(
                                  Icons.photo_camera,
                                  size: 14,
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.nickname ?? '...',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [status, ?since].join(' · '),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        EmailText(
                          user.email ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
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
              const SizedBox(height: AppSpacing.lg),
              // สูงเท่ากันทุกช่อง แม้ป้ายบางช่องยาวจนขึ้นบรรทัดใหม่
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      // StatTile มาจาก lib/widgets/stat_tile.dart
                      child: StatTile(
                        value: stats?.articles,
                        label: l10n.statLogsSaved,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // ทบทวนสำเร็จ % = ครั้งที่ตอบ "ดี/ง่าย" ÷ ครั้งที่ทบทวนทั้งหมด (ยังไม่เคยทบทวน = ขีด)
                    Expanded(
                      child: StatTile(
                        value: reviewSuccess,
                        unit: '%',
                        label: l10n.statReviewSuccess,
                        color: scheme.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: StatTile(
                        value: stats?.streakDays,
                        label: l10n.statStreak,
                        color: scheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// กล่องยืนยันลบบัญชี: อธิบายว่าจะลบอะไร + ใส่รหัสผ่าน + ปุ่มลบสีแดง
/// ลบสำเร็จ → ปิดกล่องพร้อมค่า true, รหัสผิด/เน็ตหลุด → แสดง error ในกล่อง ลองใหม่ได้
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  /// บัญชีที่ล็อกอินด้วย Google ไม่มีรหัสผ่าน → ยืนยันด้วยการเข้าสู่ระบบ Google อีกครั้ง
  final bool _usesPassword = AuthService().usesPassword;
  bool _deleting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      // AccountService มาจาก lib/services/account_service.dart
      final deleted = await AccountService().deleteAccount(
        password: _usesPassword ? _password.text : null,
      );
      if (!mounted) return;
      // false = ยกเลิกหน้าต่าง Google (ยังไม่มีอะไรถูกลบ) → กลับมาให้กดใหม่ได้
      if (deleted) {
        Navigator.pop(context, true);
      } else {
        setState(() => _deleting = false);
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: Text(l10n.deleteAccountTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteAccountBody),
              const SizedBox(height: AppSpacing.md),
              if (!_usesPassword) ...[
                Text(
                  l10n.deleteAccountGoogle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ],
              ] else
                TextFormField(
                  controller: _password,
                  enabled: !_deleting,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _confirm(),
                  decoration: InputDecoration(
                    labelText: l10n.deleteAccountPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _error,
                    errorMaxLines: 3,
                    suffixIcon: IconButton(
                      tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  // Validators มาจาก lib/core/validators.dart
                  validator: Validators.password,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _deleting ? null : _confirm,
          child: _deleting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onError,
                  ),
                )
              : Text(l10n.deleteAccountConfirm),
        ),
      ],
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

  // ContentLanguage มาจาก lib/models/content_language.dart
  late ContentLanguage _app;
  late ContentLanguage _article;
  late ContentLanguage? _tts;

  // PendingLanguages มาจาก lib/services/settings_service.dart
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
      // AppRestarter มาจาก lib/core/app_restarter.dart
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
            const SizedBox(height: AppSpacing.md),
            if (pending && !_changed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
        const SizedBox(height: AppSpacing.xs),
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
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder<String>(
        valueListenable: settings.sourceId,
        builder: (context, selected, _) => Column(
          children: [
            // ArticleSources มาจาก lib/services/sources/article_source.dart
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

/// ท้ายหน้า: โลโก้ + สโลแกน + เวอร์ชันของแอป (อ่านจากข้อมูลแอปจริง ไม่ได้พิมพ์เลขไว้เอง)
class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      children: [
        // KeepLogo มาจาก lib/widgets/keep_logo.dart
        const KeepLogo(size: 32),
        const SizedBox(height: AppSpacing.xs),
        Text(context.l10n.tagline, style: muted),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final info = snapshot.data;
            if (info == null) return const SizedBox.shrink();
            return Text(
              context.l10n.versionLabel(
                '${info.version} (${info.buildNumber})',
              ),
              style: muted,
            );
          },
        ),
      ],
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
