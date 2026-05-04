import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/router/app_router.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFAA916);
    const base = Color(0xFF151E3F);
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF6E1), Color(0xFFF7F8FC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFFFE3A7)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22151E3F),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'ARound',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: base,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.authTagline,
                            style: TextStyle(
                              color: base.withOpacity(0.7),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(
                              context,
                              Routes.login,
                              arguments: const AuthRoleArgs(userType: 'user'),
                            ),
                        icon: const Icon(Icons.person_outline_rounded),
                        label: Text(l10n.roleUser),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(
                              context,
                              Routes.login,
                              arguments: const AuthRoleArgs(userType: 'business'),
                            ),
                        icon: const Icon(Icons.business_center_outlined),
                        label: Text(l10n.roleBusiness),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Container(
                        width: 120,
                        height: 5,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(99),
                        ),
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
