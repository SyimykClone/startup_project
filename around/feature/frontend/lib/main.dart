import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';

import 'services/auth_service.dart';
import 'state/auth_state.dart';
import 'state/poi_state.dart';
import 'state/route_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  final config = AppConfig.fromEnv();
  final apiClient = ApiClient(config.apiBaseUrl);
  final authService = AuthService(apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider(create: (_) => AuthState(authService)),
        ChangeNotifierProvider(create: (_) => PoiState()),
        ChangeNotifierProvider(create: (_) => RouteState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ARound',
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: Routes.auth,
    );
  }
}
