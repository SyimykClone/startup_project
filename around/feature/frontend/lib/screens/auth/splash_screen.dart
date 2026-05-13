import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n.dart';
import '../home/app_shell_screen.dart';
import '../../state/auth_state.dart';
import 'auth_choice_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _accent = Color(0xFFFAA916);
  static const _base = Color(0xFF151E3F);
  static const _softBlue = Color(0xFF24386F);

  bool _minDelayDone = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      _minDelayDone = true;
      _tryNavigate(context.read<AuthState>());
    });
  }

  void _tryNavigate(AuthState auth) {
    if (_navigated || !_minDelayDone || auth.isLoading) return;
    _navigated = true;
    final targetScreen = auth.isAuthed
        ? const AppShellScreen()
        : const AuthChoiceScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => targetScreen,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryNavigate(auth);
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_softBlue, _base],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 28,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const _SplashCompass(),
                      const SizedBox(height: 22),
                      const Text(
                        'ARound',
                        style: TextStyle(
                          color: _base,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.splashTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _base.withOpacity(0.68),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SplashRouteLine(),
                      const SizedBox(height: 22),
                      Text(
                        auth.isLoading
                            ? 'Подготавливаем ваше путешествие...'
                            : 'Ищем маршруты, туры и места рядом...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _base.withOpacity(0.58),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(
                          minHeight: 6,
                          backgroundColor: Color(0xFFE9EDF7),
                          valueColor: AlwaysStoppedAnimation<Color>(_base),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.16)),
                  ),
                  child: Text(
                    'Маршруты · Туры · AR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class _SplashCompass extends StatelessWidget {
  const _SplashCompass();

  static const _accent = Color(0xFFFAA916);
  static const _base = Color(0xFF151E3F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FC),
        shape: BoxShape.circle,
        border: Border.all(color: _base.withOpacity(0.1)),
      ),
      child: Center(
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: _base,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33151E3F),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.explore_rounded, color: Colors.white, size: 42),
              Positioned(
                right: 11,
                top: 11,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashRouteLine extends StatelessWidget {
  const _SplashRouteLine();

  static const _accent = Color(0xFFFAA916);
  static const _base = Color(0xFF151E3F);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _RouteDot(icon: Icons.my_location_rounded),
        Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _base.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.68,
              child: Container(
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        const _RouteDot(icon: Icons.place_rounded, filled: true),
      ],
    );
  }
}

class _RouteDot extends StatelessWidget {
  const _RouteDot({required this.icon, this.filled = false});

  final IconData icon;
  final bool filled;

  static const _accent = Color(0xFFFAA916);
  static const _base = Color(0xFF151E3F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: filled ? _accent : const Color(0xFFF4F6FC),
        shape: BoxShape.circle,
        border: Border.all(color: _base.withOpacity(0.1)),
      ),
      child: Icon(icon, color: _base, size: 21),
    );
  }
}
