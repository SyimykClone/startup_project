import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthOnboardingService {
  static const _authChoiceSeenKey = 'auth_choice_onboarding_seen';

  static Future<void> showAuthChoiceIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_authChoiceSeenKey) == true || !context.mounted) return;
    await showAuthChoiceIntro(context);
    await prefs.setBool(_authChoiceSeenKey, true);
  }

  static Future<void> showAuthChoiceHint(BuildContext context) {
    return showAuthChoiceIntro(context);
  }

  static Future<void> showAuthChoiceIntro(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AuthChoiceOnboardingDialog(),
    );
  }
}

class _AuthChoiceOnboardingDialog extends StatefulWidget {
  const _AuthChoiceOnboardingDialog();

  @override
  State<_AuthChoiceOnboardingDialog> createState() =>
      _AuthChoiceOnboardingDialogState();
}

class _AuthChoiceOnboardingDialogState
    extends State<_AuthChoiceOnboardingDialog> {
  static const _accent = Color(0xFFFAA916);
  static const _base = Color(0xFF151E3F);

  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final steps = _steps(isRu);
    final current = steps[_step];
    final isLast = _step == steps.length - 1;

    return AlertDialog(
      backgroundColor: Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(current.icon, color: _base),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              current.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _base,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current.description,
            style: TextStyle(
              color: _base.withOpacity(0.82),
              height: 1.4,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(
              steps.length,
              (index) => Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == steps.length - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: index <= _step
                        ? _accent
                        : _base.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isRu ? '\u041f\u0440\u043e\u043f\u0443\u0441\u0442\u0438\u0442\u044c' : 'Skip'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: _base,
          ),
          onPressed: () {
            if (isLast) {
              Navigator.of(context).pop();
              return;
            }
            setState(() => _step += 1);
          },
          child: Text(
            isLast
                ? (isRu ? '\u041d\u0430\u0447\u0430\u0442\u044c' : 'Start')
                : (isRu ? '\u0414\u0430\u043b\u0435\u0435' : 'Next'),
          ),
        ),
      ],
    );
  }

  List<_OnboardingStep> _steps(bool isRu) {
    return [
      _OnboardingStep(
        icon: Icons.waving_hand_rounded,
        title: isRu
            ? '\u0414\u043e\u0431\u0440\u043e \u043f\u043e\u0436\u0430\u043b\u043e\u0432\u0430\u0442\u044c'
            : 'Welcome',
        description: isRu
            ? '\u0412\u044b \u0432\u043f\u0435\u0440\u0432\u044b\u0435 \u0432 \u043d\u0430\u0448\u0435\u043c \u043f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u0438. \u0414\u0430\u0432\u0430\u0439\u0442\u0435 \u043f\u0440\u043e\u0439\u0434\u0451\u043c \u043a\u043e\u0440\u043e\u0442\u043a\u0438\u0439 \u0438\u043d\u0441\u0442\u0440\u0443\u043a\u0442\u0430\u0436, \u0447\u0442\u043e\u0431\u044b \u0431\u044b\u0441\u0442\u0440\u043e \u043f\u043e\u043d\u044f\u0442\u044c, \u0441 \u0447\u0435\u0433\u043e \u043d\u0430\u0447\u0430\u0442\u044c.'
            : 'It looks like this is your first time in the app. Let us walk through a short introduction so you can get started quickly.',
      ),
      _OnboardingStep(
        icon: Icons.groups_rounded,
        title: isRu
            ? '\u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0440\u043e\u043b\u044c'
            : 'Choose your role',
        description: isRu
            ? '\u041e\u0431\u044b\u0447\u043d\u044b\u0439 \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044c \u043f\u043e\u0434\u043e\u0439\u0434\u0451\u0442 \u0434\u043b\u044f \u043f\u043e\u0438\u0441\u043a\u0430 \u043c\u0435\u0441\u0442, \u043f\u043e\u0441\u0442\u0440\u043e\u0435\u043d\u0438\u044f \u043c\u0430\u0440\u0448\u0440\u0443\u0442\u043e\u0432 \u0438 \u0441\u043e\u0445\u0440\u0430\u043d\u0435\u043d\u0438\u044f \u043b\u043e\u043a\u0430\u0446\u0438\u0439. \u0411\u0438\u0437\u043d\u0435\u0441-\u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044c \u043d\u0443\u0436\u0435\u043d, \u0435\u0441\u043b\u0438 \u0432\u044b \u0445\u043e\u0442\u0438\u0442\u0435 \u0441\u043e\u0437\u0434\u0430\u0432\u0430\u0442\u044c \u0438 \u043f\u0443\u0431\u043b\u0438\u043a\u043e\u0432\u0430\u0442\u044c \u0442\u0443\u0440\u044b.'
            : 'Choose regular user if you want to browse places, build routes, and save locations. Choose business if you want to create and publish tours.',
      ),
      _OnboardingStep(
        icon: Icons.login_rounded,
        title: isRu
            ? '\u0414\u0430\u043b\u044c\u0448\u0435 \u2014 \u0432\u0445\u043e\u0434 \u0438\u043b\u0438 \u0440\u0435\u0433\u0438\u0441\u0442\u0440\u0430\u0446\u0438\u044f'
            : 'Next: sign in or sign up',
        description: isRu
            ? '\u041f\u043e\u0441\u043b\u0435 \u0432\u044b\u0431\u043e\u0440\u0430 \u0440\u043e\u043b\u0438 \u043e\u0442\u043a\u0440\u043e\u0435\u0442\u0441\u044f \u044d\u043a\u0440\u0430\u043d \u0432\u0445\u043e\u0434\u0430. \u0415\u0441\u043b\u0438 \u0430\u043a\u043a\u0430\u0443\u043d\u0442\u0430 \u0435\u0449\u0451 \u043d\u0435\u0442, \u043d\u0430\u0436\u043c\u0438\u0442\u0435 \u043a\u043d\u043e\u043f\u043a\u0443 \u0440\u0435\u0433\u0438\u0441\u0442\u0440\u0430\u0446\u0438\u0438 \u0438 \u0441\u043e\u0437\u0434\u0430\u0439\u0442\u0435 \u043f\u0440\u043e\u0444\u0438\u043b\u044c.'
            : 'After you choose a role, the sign-in screen will open. If you do not have an account yet, use the sign-up button there to create one.',
      ),
    ];
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
