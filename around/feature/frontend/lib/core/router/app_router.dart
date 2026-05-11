import 'package:flutter/material.dart';

import '../../screens/auth/auth_choice_onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/home/app_shell_screen.dart';
import '../../screens/poi/poi_detail_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../models/poi.dart';

class Routes {
  static const splash = '/splash';
  static const auth = '/';
  static const login = '/sign-in';
  static const register = '/sign-up';
  static const map = '/map';
  static const editProfile = '/profile/edit';
  static const poiDetail = '/poi-detail';
}

class AuthRoleArgs {
  final String userType;

  const AuthRoleArgs({required this.userType});
}

class AppShellArgs {
  final int initialIndex;
  final Poi? initialPoi;

  const AppShellArgs({
    this.initialIndex = 2,
    this.initialPoi,
  });
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case Routes.auth:
        return MaterialPageRoute(
          builder: (_) => const AuthChoiceOnboardingScreen(),
        );

      case Routes.login:
        final args = settings.arguments;
        final roleArgs = args is AuthRoleArgs ? args : null;
        return MaterialPageRoute(
          builder: (_) => LoginScreen(initialUserType: roleArgs?.userType),
        );

      case Routes.register:
        final args = settings.arguments;
        final roleArgs = args is AuthRoleArgs ? args : null;
        return MaterialPageRoute(
          builder: (_) => RegisterScreen(initialUserType: roleArgs?.userType),
        );

      case Routes.map:
        final args = settings.arguments;
        final shellArgs = args is AppShellArgs ? args : null;
        return MaterialPageRoute(
          builder: (_) => AppShellScreen(
            initialIndex: shellArgs?.initialIndex ?? 2,
            initialPoi: shellArgs?.initialPoi,
          ),
        );

      case Routes.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case Routes.poiDetail:
        final poi = settings.arguments as Poi;
        return MaterialPageRoute(builder: (_) => PoiDetailScreen(poi: poi));

      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
