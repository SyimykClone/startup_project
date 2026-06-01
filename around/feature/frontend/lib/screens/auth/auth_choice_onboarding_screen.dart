import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/onboarding/auth_onboarding_service.dart';
import '../../core/router/app_router.dart';

class AuthChoiceOnboardingScreen extends StatefulWidget {
  const AuthChoiceOnboardingScreen({super.key});

  @override
  State<AuthChoiceOnboardingScreen> createState() =>
      _AuthChoiceOnboardingScreenState();
}

class _AuthChoiceOnboardingScreenState
    extends State<AuthChoiceOnboardingScreen> {
  bool _introScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_introScheduled) return;
    _introScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AuthOnboardingService.showAuthChoiceIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFAA916);
    const base = Color(0xFF151E3F);
    const outerBlue = Color(0xFF071C36);
    final l10n = context.l10n;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B2A4D), outerBlue],
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: isRu ? 'Подсказка' : 'Help',
                        onPressed: () =>
                            AuthOnboardingService.showAuthChoiceHint(context),
                        icon: const Icon(
                          Icons.help_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 28,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              color: base,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.travel_explore_rounded,
                              color: accent,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 14),
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
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: base.withOpacity(0.7),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _RoleChoiceCard(
                            icon: Icons.person_outline_rounded,
                            title: l10n.roleUser,
                            subtitle: isRu
                                ? 'Маршруты, избранное, AR и туры'
                                : 'Routes, favorites, AR and tours',
                            filled: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              Routes.login,
                              arguments: const AuthRoleArgs(userType: 'user'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _RoleChoiceCard(
                            icon: Icons.business_center_outlined,
                            title: l10n.roleBusiness,
                            subtitle: isRu
                                ? 'Создание и публикация туров'
                                : 'Create and publish tours',
                            onTap: () => Navigator.pushNamed(
                              context,
                              Routes.login,
                              arguments:
                                  const AuthRoleArgs(userType: 'business'),
                            ),
                          ),
                        ],
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

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFAA916);
    const base = Color(0xFF151E3F);
    return Material(
      color: filled ? base : const Color(0xFFF4F6FC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: filled ? accent : Colors.white,
                foregroundColor: base,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: filled ? Colors.white : base,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: filled
                            ? Colors.white.withOpacity(0.7)
                            : base.withOpacity(0.62),
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: filled ? accent : base.withOpacity(0.58),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
