import 'package:flutter/material.dart';
import '../../core/router/app_router.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "ARound",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 28),
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: SizedBox(
                      height: 44,
                      child: SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: () => Navigator.pushNamed(context, Routes.login),
                          child: const Text("Sign in"),
                        ),
                      ),                    ),
                  ),
                  const SizedBox(height: 12),
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: () => Navigator.pushNamed(context, Routes.register),
                        child: const Text("Sign up"),
                      ),
                    ),
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
