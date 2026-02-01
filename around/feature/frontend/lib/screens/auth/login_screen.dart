import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../state/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: "test@mail.com");
  final _pass = TextEditingController(text: "123456");

  @override
  void initState() {
    super.initState();
    context.read<AuthState>().init().then((_) {
      if (context.read<AuthState>().isAuthed) {
        Navigator.pushReplacementNamed(context, Routes.map);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            TextField(
              controller: _pass,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      await context.read<AuthState>().login(_email.text.trim(), _pass.text.trim());
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, Routes.map);
                      }
                    },
              child: auth.isLoading ? const CircularProgressIndicator() : const Text("Login"),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, Routes.register),
              child: const Text("Create account"),
            )
          ],
        ),
      ),
    );
  }
}
