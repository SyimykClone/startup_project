import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  final String apiBaseUrl;
  final bool useMock;
  final String twogisApiKey;

  AppConfig({
    required this.apiBaseUrl,
    required this.useMock,
    required this.twogisApiKey,
  });

  factory AppConfig.fromEnv() {
    final api = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final mock = (dotenv.env['USE_MOCK'] ?? 'true').toLowerCase() == 'true';
    final twogisApiKey = dotenv.env['TWOGIS_API_KEY'] ?? '';

    return AppConfig(
      apiBaseUrl: api,
      useMock: mock,
      twogisApiKey: twogisApiKey,
    );
  }
}
