import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';

class AuthService {
  final ApiClient api;
  final TokenStorage _storage = TokenStorage();

  AuthService(this.api);

  Future<void> login(String email, String password) async {
    final res = await api.dio.post('/api/auth/login', data: {
      "email": email,
      "password": password,
    });

    final token = res.data['access_token'] as String;
    await _storage.saveToken(token);
    api.setToken(token);
  }

  Future<void> register(String username, String email, String password) async {
    final res = await api.dio.post('/api/auth/register', data: {
      "username": username,
      "email": email,
      "password": password,
    });

    final token = res.data['access_token'] as String;
    await _storage.saveToken(token);
    api.setToken(token);
  }

  Future<void> logout() async {
    try {
      await api.dio.post('/api/auth/logout');
    } catch (_) {}
    await _storage.clear();
    api.setToken(null);
  }

  Future<String?> getToken() async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      api.setToken(token);
    }
    return token;
  }
}
