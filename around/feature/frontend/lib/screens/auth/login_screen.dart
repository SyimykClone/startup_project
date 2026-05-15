import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/i18n/l10n.dart';
import '../../core/router/app_router.dart';
import '../../state/auth_state.dart';
import '../../utils/app_error_text.dart';
import '../../widgets/error_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialUserType});

  final String? initialUserType;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _googleLoading = false;

  bool _hide = true;

  bool _isValidEmail(String v) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(v);
  }

  bool _isStrongEnoughPassword(String v) {
    return v.length >= 6;
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    final auth = context.read<AuthState>();

    final success = await auth.login(
      _email.text.trim().toLowerCase(),
      _pass.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      Navigator.pushReplacementNamed(context, Routes.map);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    try {
      final google = GoogleSignIn(
        scopes: const ["email", "profile"],
        serverClientId:
            "93446166912-o85fbrck4ss9a1kus6dir4b2b00856tu.apps.googleusercontent.com",
      );
      try {
        await google.signOut();
      } catch (_) {}
      final account = await google.signIn();
      if (account == null) {
        return;
      }

      final auth = await account.authentication;
      if (auth.idToken == null || auth.idToken!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showMaterialBanner(
          ErrorBanner.build(context, message: context.l10n.googleTokenEmpty),
        );
        return;
      }

      final success = await context.read<AuthState>().loginWithGoogle(
        auth.idToken!,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        Navigator.pushReplacementNamed(context, Routes.map);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showMaterialBanner(
        ErrorBanner.build(
          context,
          message: AppErrorText.fromObject(context, e),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  Future<void> _openResetPasswordDialog() async {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final emailCtrl = TextEditingController(text: _email.text.trim());
    final passCtrl = TextEditingController();
    final repeatCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var hidePass = true;
    var hideRepeat = true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(isRu ? 'Восстановление пароля' : 'Password recovery'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isRu
                            ? 'Введите email аккаунта и новый пароль.'
                            : 'Enter your account email and a new password.',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: context.l10n.email),
                        validator: (value) {
                          final email = (value ?? '').trim().toLowerCase();
                          if (email.isEmpty) return context.l10n.emailRequired;
                          if (!_isValidEmail(email)) return context.l10n.emailInvalid;
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: passCtrl,
                        obscureText: hidePass,
                        decoration: InputDecoration(
                          labelText: isRu ? 'Новый пароль' : 'New password',
                          helperText: context.l10n.passwordMin6,
                          suffixIcon: IconButton(
                            onPressed: () => setModalState(() => hidePass = !hidePass),
                            icon: Icon(
                              hidePass ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final pass = (value ?? '').trim();
                          if (pass.isEmpty) return context.l10n.passwordRequired;
                          if (!_isStrongEnoughPassword(pass)) return context.l10n.passwordWeak;
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: repeatCtrl,
                        obscureText: hideRepeat,
                        decoration: InputDecoration(
                          labelText: isRu ? 'Повторите пароль' : 'Repeat password',
                          suffixIcon: IconButton(
                            onPressed: () => setModalState(() => hideRepeat = !hideRepeat),
                            icon: Icon(
                              hideRepeat ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim() != passCtrl.text.trim()) {
                            return isRu ? 'Пароли не совпадают' : 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final ok = formKey.currentState?.validate() ?? false;
                    if (!ok) return;
                    Navigator.pop(context, true);
                  },
                  child: Text(isRu ? 'Сохранить пароль' : 'Save password'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    if (!mounted) return;

    final success = await context.read<AuthState>().resetPassword(
          emailCtrl.text.trim().toLowerCase(),
          passCtrl.text.trim(),
        );

    if (!mounted) return;
    if (success) {
      _email.text = emailCtrl.text.trim().toLowerCase();
      _pass.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRu
                ? 'Пароль обновлён. Теперь войдите с новым паролем.'
                : 'Password updated. Now sign in with the new password.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFF151E3F);
    const outerBlue = Color(0xFF071C36);
    final l10n = context.l10n;
    final helpTooltip = Localizations.localeOf(context).languageCode == 'ru'
        ? 'Подсказка'
        : 'Help';

    final auth = context.watch<AuthState>();
    final disabled = auth.isLoading || _googleLoading;

    if (auth.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        ScaffoldMessenger.of(
          context,
        ).showMaterialBanner(ErrorBanner.build(context, message: auth.error!));
        context.read<AuthState>().clearError();
      });
    }

    return Scaffold(
      backgroundColor: outerBlue,
      appBar: AppBar(title: Text(l10n.signIn)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B2A4D), outerBlue],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 26,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: base,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.login_rounded,
                                color: Color(0xFFFAA916),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.loginWelcomeBack,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: base,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.loginContinue,
                            style: TextStyle(color: base.withOpacity(0.72)),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _email,
                            enabled: !disabled,
                            decoration: InputDecoration(
                              labelText: l10n.email,
                              hintText: l10n.emailHint,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: (v) {
                              final s = (v ?? '').trim().toLowerCase();
                              if (s.isEmpty) return l10n.emailRequired;
                              if (!_isValidEmail(s)) return l10n.emailInvalid;
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass,
                            enabled: !disabled,
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              helperText: l10n.passwordMin6,
                              suffixIcon: IconButton(
                                onPressed: disabled
                                    ? null
                                    : () => setState(() => _hide = !_hide),
                                icon: Icon(
                                  _hide
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            obscureText: _hide,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return l10n.passwordRequired;
                              if (!_isStrongEnoughPassword(s)) {
                                return l10n.passwordWeak;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: disabled ? null : _openResetPasswordDialog,
                              child: Text(
                                Localizations.localeOf(context).languageCode == 'ru'
                                    ? 'Забыли пароль?'
                                    : 'Forgot password?',
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 46,
                            child: FilledButton(
                              onPressed: disabled ? null : _submit,
                              child: auth.isLoading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(l10n.signingIn),
                                      ],
                                    )
                                  : Text(l10n.signIn),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: disabled ? null : _signInWithGoogle,
                              child: _googleLoading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(l10n.connectingGoogle),
                                      ],
                                    )
                                  : Text(l10n.continueWithGoogle),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${l10n.noAccount} "),
                              TextButton(
                                onPressed: disabled
                                    ? null
                                    : () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).hideCurrentMaterialBanner();
                                        Navigator.pushReplacementNamed(
                                          context,
                                          Routes.register,
                                          arguments: AuthRoleArgs(
                                            userType:
                                                widget.initialUserType ?? 'user',
                                          ),
                                        );
                                      },
                                child: Text(l10n.signUp),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
