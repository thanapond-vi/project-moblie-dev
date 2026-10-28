import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/validators.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../widgets/ui_helpers.dart';
import '../core/theme.dart';

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
  final _auth = AuthService();

  bool _isRegister = false;
  bool _isLoading = false;
  bool _obscure = true;

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
    } on AppException catch (e) {
      // หลัง await หน้าจออาจถูกปิดไปแล้ว ต้องเช็ก mounted ก่อนใช้ context
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'KEEP',
                      textAlign: TextAlign.center,
                      style: AppTheme.wordmarkLarge(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _isRegister ? l10n.register : l10n.login,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      textInputAction: _isRegister
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: (_) => _isRegister ? null : _submit(),
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
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    if (_isRegister) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.confirmPassword,
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                        validator: (v) => Validators.confirmPassword(
                          v,
                          _passwordController.text,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
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
                          : Text(_isRegister ? l10n.register : l10n.login),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: Text(
                        _isRegister ? l10n.haveAccount : l10n.noAccount,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
