import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/validators.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../widgets/ui_helpers.dart';
import '../core/spacing.dart';
import '../core/theme.dart';
import '../widgets/google_mark.dart';
import '../widgets/keep_logo.dart';

/// หน้าจอ 1: Login / Register (ใช้หน้าเดียว สลับโหมดด้วยปุ่มด้านล่าง)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // GlobalKey ใช้สั่ง validate() ทุกช่องในฟอร์มพร้อมกัน
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  // AuthService มาจาก lib/services/auth_service.dart
  final _auth = AuthService();

  bool _isRegister = false;
  bool _isLoading = false;
  bool _obscure = true;

  /// กำลังส่งอีเมลตั้งรหัสใหม่ (กันกดซ้ำจนโดน too-many-requests)
  bool _sendingReset = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 1) ตรวจฟอร์มก่อน ถ้าไม่ผ่านจะไม่เรียก Firebase เลย
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // 2) แสดง loading และปิดปุ่ม กันผู้ใช้กดซ้ำ
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      if (_isRegister) {
        await _auth.register(email, password);
      } else {
        await _auth.signIn(email, password);
      }
      // 3) สำเร็จ: ไม่ต้อง navigate เอง AuthGate จะเห็น user ใหม่จาก stream แล้วพาไป Home
      // AppException มาจาก lib/core/app_exception.dart
    } on AppException catch (e) {
      // หลัง await หน้าจออาจถูกปิดไปแล้ว ต้องเช็ก mounted ก่อนใช้ context
      // showMessage มาจาก lib/widgets/ui_helpers.dart
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _confirmController.clear();
    });
    _formKey.currentState?.reset();
  }

  /// เข้าสู่ระบบ/สมัครด้วย Google: บัญชีใหม่จะถูกสร้างให้อัตโนมัติ (แล้วไปหน้าตั้งค่าเริ่มต้นเหมือนสมัครปกติ)
  /// สำเร็จแล้ว AuthGate เห็น user จาก stream แล้วพาไปหน้าแรกเอง ไม่ต้อง navigate
  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithGoogle(); // false = ผู้ใช้ยกเลิก ไม่ต้องแจ้งอะไร
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ลืมรหัสผ่าน: กรอก/ยืนยันอีเมล → Firebase ส่งลิงก์ตั้งรหัสใหม่ไปที่อีเมลนั้น
  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initial: _emailController.text),
    );
    if (email == null || !mounted || _sendingReset) return;
    setState(() => _sendingReset = true);
    try {
      await _auth.sendPasswordReset(email);
      // context.l10n มาจาก lib/l10n/l10n.dart
      if (mounted) showMessage(context, context.l10n.resetSent(email.trim()));
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // AppSpacing มาจาก lib/core/spacing.dart
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _Emblem()),
                  const SizedBox(height: AppSpacing.lg),
                  // letterSpacing เว้นท้ายตัวสุดท้ายด้วย → ดันด้านหน้าเท่ากัน ให้คำอยู่กลางจริง
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      // AppTheme มาจาก lib/core/theme.dart
                      start: AppTheme.wordmarkLarge(context).letterSpacing ?? 0,
                    ),
                    child: Text(
                      'KEEP',
                      textAlign: TextAlign.center,
                      style: AppTheme.wordmarkLarge(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(child: _StatusPill(label: l10n.authStatusPill)),
                  const SizedBox(height: AppSpacing.xl),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isRegister ? l10n.register : l10n.login,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: l10n.email,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                // Validators มาจาก lib/core/validators.dart
                                validator: Validators.email,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                autofillHints: [
                                  _isRegister
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                textInputAction: _isRegister
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    _isRegister ? null : _submit(),
                                decoration: InputDecoration(
                                  labelText: l10n.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure
                                        ? l10n.showPassword
                                        : l10n.hidePassword,
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: Validators.password,
                              ),
                              if (_isRegister) ...[
                                const SizedBox(height: AppSpacing.sm),
                                TextFormField(
                                  controller: _confirmController,
                                  obscureText: _obscure,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: l10n.confirmPassword,
                                    prefixIcon: const Icon(
                                      Icons.lock_reset_outlined,
                                    ),
                                  ),
                                  validator: (v) => Validators.confirmPassword(
                                    v,
                                    _passwordController.text,
                                  ),
                                ),
                              ] else
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: TextButton(
                                    onPressed: _isLoading || _sendingReset
                                        ? null
                                        : _forgotPassword,
                                    child: Text(l10n.forgotPassword),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        _isRegister
                                            ? l10n.register
                                            : l10n.login,
                                      ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              // ── หรือ ──
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      l10n.orDivider,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  foregroundColor: scheme.onSurface,
                                ),
                                onPressed: _isLoading ? null : _google,
                                // GoogleMark มาจาก lib/widgets/google_mark.dart
                                icon: const GoogleMark(),
                                label: Text(l10n.continueWithGoogle),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              // Apple: ยังไม่มีระบบจริง แสดงปุ่มไว้ก่อน แตะแล้วบอกว่าเร็วๆ นี้
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  foregroundColor: scheme.onSurface,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => showMessage(
                                        context,
                                        l10n.appleComingSoon,
                                      ),
                                icon: const Icon(Icons.apple),
                                label: Text(l10n.continueWithApple),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              TextButton(
                                onPressed: _isLoading ? null : _toggleMode,
                                child: Text(
                                  _isRegister
                                      ? l10n.haveAccount
                                      : l10n.noAccount,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(
                          l10n.authFooter,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// โลโก้ในวงกลมบนพื้นผิวขั้นถัดไป มีแสงอำพันจางๆ รอบวง (แสงจากโคมไฟ)
class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // ReadingLampColors มาจาก lib/core/theme.dart
    final lamp = ReadingLampColors.of(context);
    return Container(
      width: 112,
      height: 112,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            lamp.glowHalo.withValues(alpha: 0.16 * lamp.glowStrength),
            lamp.glowHalo.withValues(alpha: 0),
          ],
        ),
      ),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainerLow,
          border: Border.all(color: scheme.outlineVariant),
        ),
        // KeepLogo มาจาก lib/widgets/keep_logo.dart
        child: const KeepLogo(size: 52, semanticLabel: 'KEEP'),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainer,
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// กล่องลืมรหัสผ่าน: ตรวจรูปแบบอีเมลก่อน แล้วคืนอีเมลให้หน้าหลักส่งลิงก์
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initial});

  final String initial;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial.trim());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.resetTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.resetBody),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.send,
              onFieldSubmitted: (_) => _send(),
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: Validators.email,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: _send,
          child: Text(l10n.resetSend),
        ),
      ],
    );
  }
}
