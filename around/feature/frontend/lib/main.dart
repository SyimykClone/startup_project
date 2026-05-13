import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/i18n/l10n.dart';
import 'l10n/generated/app_localizations.dart';

import 'services/auth_service.dart';
import 'state/auth_state.dart';
import 'state/locale_state.dart';
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
        ChangeNotifierProvider(
          create: (_) {
            final state = AuthState(authService);
            state.init();
            return state;
          },
        ),
        ChangeNotifierProvider(create: (_) => PoiState()),
        ChangeNotifierProvider(create: (_) => RouteState()),
        ChangeNotifierProvider(
          create: (_) {
            final state = LocaleState();
            state.init();
            return state;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFAA916);
    const base = Color(0xFF151E3F);
    const surface = Color(0xFFF4F6FC);
    const outerBlue = Color(0xFF071C36);
    final locale = context.watch<LocaleState>().locale;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: accent,
              primary: accent,
              secondary: base,
              surface: Colors.white,
            ).copyWith(
              onPrimary: base,
              onSecondary: Colors.white,
              onSurface: base,
              surface: surface,
            ),
        scaffoldBackgroundColor: outerBlue,
        appBarTheme: const AppBarTheme(
          backgroundColor: outerBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD7DDEE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD7DDEE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accent, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          floatingLabelStyle: const TextStyle(color: base),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0.8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: base,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          titleLarge: TextStyle(color: base, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(color: base),
          bodyMedium: TextStyle(color: base),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: base,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: base,
            side: const BorderSide(color: base, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: Routes.splash,
    );
  }
}
