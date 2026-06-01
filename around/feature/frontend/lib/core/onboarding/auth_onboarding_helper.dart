import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthOnboardingHelper {
  static const _authChoiceSeenKey = 'auth_choice_onboarding_seen';

  static Future<void> showAuthChoiceHintIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_authChoiceSeenKey) == true || !context.mounted) return;
    await showAuthChoiceHint(context);
    await prefs.setBool(_authChoiceSeenKey, true);
  }

  static Future<void> showLoginHintIfNeeded(
    BuildContext context, {
    required String userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'login_onboarding_seen_$userType';
    if (prefs.getBool(key) == true || !context.mounted) return;
    await showLoginHint(context, userType: userType);
    await prefs.setBool(key, true);
  }

  static Future<void> showRegisterHintIfNeeded(
    BuildContext context, {
    required String userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'register_onboarding_seen_$userType';
    if (prefs.getBool(key) == true || !context.mounted) return;
    await showRegisterHint(context, userType: userType);
    await prefs.setBool(key, true);
  }

  static Future<void> showAuthChoiceHint(BuildContext context) async {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    await _showHelpDialog(
      context,
      title: isRu ? 'С чего начать?' : 'How to get started',
      steps: [
        isRu
            ? '1. Сначала выберите роль: обычный пользователь или бизнес-пользователь.'
            : '1. First choose your role: regular user or business user.',
        isRu
            ? '2. Если у вас уже есть аккаунт, выполните вход на следующем экране.'
            : '2. If you already have an account, sign in on the next screen.',
        isRu
            ? '3. Если аккаунта нет, нажмите регистрацию и создайте профиль.'
            : '3. If you do not have an account yet, open sign up and create one.',
      ],
    );
  }

  static Future<void> showLoginHint(
    BuildContext context, {
    required String userType,
  }) async {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final roleText = _roleTitle(isRu: isRu, userType: userType);
    await _showHelpDialog(
      context,
      title: isRu ? 'Подсказка по входу' : 'Sign-in tips',
      steps: [
        isRu
            ? 'Вы выбрали роль: $roleText.'
            : 'You selected the $roleText role.',
        isRu
            ? 'Введите email и пароль, если аккаунт уже создан.'
            : 'Enter your email and password if your account already exists.',
        isRu
            ? 'Если аккаунта ещё нет, перейдите по кнопке регистрации внизу экрана.'
            : 'If you do not have an account yet, use the sign-up button at the bottom of the screen.',
      ],
    );
  }

  static Future<void> showRegisterHint(
    BuildContext context, {
    required String userType,
  }) async {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final roleText = _roleTitle(isRu: isRu, userType: userType);
    await _showHelpDialog(
      context,
      title: isRu ? 'Подсказка по регистрации' : 'Sign-up tips',
      steps: [
        isRu
            ? 'Вы создаёте аккаунт с ролью: $roleText.'
            : 'You are creating an account with the $roleText role.',
        isRu
            ? 'Укажите имя пользователя, email и пароль, затем подтвердите пароль.'
            : 'Enter your username, email, and password, then confirm the password.',
        isRu
            ? 'После регистрации приложение автоматически откроет основную часть сервиса.'
            : 'After registration, the app will automatically open the main part of the service.',
      ],
    );
  }

  static String _roleTitle({required bool isRu, required String userType}) {
    if (userType == 'business') {
      return isRu ? 'бизнес-пользователь' : 'business';
    }
    return isRu ? 'обычный пользователь' : 'regular user';
  }

  static Future<void> _showHelpDialog(
    BuildContext context, {
    required String title,
    required List<String> steps,
  }) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps
              .map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(step),
                ),
              )
              .toList(),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isRu ? 'Понятно' : 'Got it'),
          ),
        ],
      ),
    );
  }
}
