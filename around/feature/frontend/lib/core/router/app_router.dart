import 'package:flutter/material.dart';

import '../../screens/auth/auth_choice_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/map_screen.dart';
import '../../screens/home/poi_list_screen.dart';
import '../../screens/poi/poi_detail_screen.dart';
import '../../models/poi.dart';

class Routes {
  static const auth = '/';
  static const login = '/sign-in';
  static const register = '/sign-up';
  static const map = '/map';
  static const poiList = '/poi-list';
  static const poiDetail = '/poi-detail';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.auth:
        return MaterialPageRoute(builder: (_) => const AuthChoiceScreen());

      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case Routes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case Routes.map:
        return MaterialPageRoute(builder: (_) => const MapScreen());

      case Routes.poiList:
        return MaterialPageRoute(builder: (_) => const PoiListScreen());

      case Routes.poiDetail:
        final poi = settings.arguments as Poi;
        return MaterialPageRoute(builder: (_) => PoiDetailScreen(poi: poi));

      default:
        return MaterialPageRoute(builder: (_) => const AuthChoiceScreen());
    }
  }
}
