import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/i18n/l10n.dart';
import '../../core/router/app_router.dart';
import '../../state/auth_state.dart';
import '../../widgets/error_banner.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _googleLoading = false;

  bool _hide1 = true;
  bool _hide2 = true;

  bool _isValidEmail(String v) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(v);
  }

  bool _isStrongPassword(String v) {
    final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
    final hasLower = RegExp(r'[a-z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    return v.length >= 6 && hasUpper && hasLower && hasDigit;
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    final auth = context.read<AuthState>();

    final success = await auth.register(
      _username.text.trim(),
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
          message: context.l10n.googleSignInFailed(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFF151E3F);
    final l10n = context.l10n;

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
      appBar: AppBar(title: Text(l10n.signUp)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E8), Color(0xFFF7F8FC)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: base.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.registerCreateAccount,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: base,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.registerSubtitle,
                            style: TextStyle(color: base.withOpacity(0.72)),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _username,
                            enabled: !disabled,
                            decoration: InputDecoration(
                              labelText: l10n.username,
                              hintText: l10n.usernameHint,
                            ),
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return l10n.usernameRequired;
                              if (s.length < 3) {
                                return l10n.usernameMin;
                              }
                              if (s.length > 20) {
                                return l10n.usernameMax;
                              }
                              if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(s)) {
                                return l10n.usernameAllowedChars;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
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
                              helperText: l10n.passwordRule,
                              suffixIcon: IconButton(
                                onPressed: disabled
                                    ? null
                                    : () => setState(() => _hide1 = !_hide1),
                                icon: Icon(
                                  _hide1
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            obscureText: _hide1,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return l10n.passwordRequired;
                              if (!_isStrongPassword(s)) {
                                return l10n.passwordStrongRule;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass2,
                            enabled: !disabled,
                            decoration: InputDecoration(
                              labelText: l10n.confirmPassword,
                              suffixIcon: IconButton(
                                onPressed: disabled
                                    ? null
                                    : () => setState(() => _hide2 = !_hide2),
                                icon: Icon(
                                  _hide2
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            obscureText: _hide2,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return l10n.confirmPasswordRequired;
                              if (s != _pass.text.trim()) return l10n.passwordsNotMatch;
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
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
                                        Text(l10n.creating),
                                      ],
                                    )
                                  : Text(l10n.createAccount),
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
                              Text("${l10n.alreadyAccount} "),
                              TextButton(
                                onPressed: disabled
                                    ? null
                                    : () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).hideCurrentMaterialBanner();
                                        Navigator.pushReplacementNamed(
                                          context,
                                          Routes.login,
                                        );
                                      },
                                child: Text(l10n.signIn),
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
