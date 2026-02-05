import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../state/auth_state.dart';

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

  bool _hide1 = true;
  bool _hide2 = true;

  bool _isValidEmail(String v) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(v);
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

    final auth = context.read<AuthState>();

    await auth.register(
      _email.text.trim().toLowerCase(),
      _pass.text.trim(),
    );

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.map);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Sign up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: "Username"),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return "Username is required";
                  if (s.length < 5) return "Username must be at least 5 characters";
                  if (s.length > 15) return "Username must be at most 15 characters";
                  return null;
                },
              ),

              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return "Email is required";
                  if (!_isValidEmail(s)) return "Enter a valid email";
                  return null;
                },
              ),

              TextFormField(
                controller: _pass,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _hide1 = !_hide1),
                    icon: Icon(_hide1 ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                obscureText: _hide1,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return "Password is required";
                  if (s.length < 6) return "Password must be at least 6 characters";
                  return null;
                },
              ),

              TextFormField(
                controller: _pass2,
                decoration: InputDecoration(
                  labelText: "Confirm password",
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _hide2 = !_hide2),
                    icon: Icon(_hide2 ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                obscureText: _hide2,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return "Please confirm your password";
                  if (s != _pass.text.trim()) return "Passwords do not match";
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Create account"),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
                    child: const Text("Sign in"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
