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
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _pass, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      await context.read<AuthState>().register(_email.text.trim(), _pass.text.trim());
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, Routes.map);
                      }
                    },
              child: auth.isLoading ? const CircularProgressIndicator() : const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
