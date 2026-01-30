import '../core/storage/token_storage.dart';

class AuthService {
  final TokenStorage _storage = TokenStorage();

  Future<void> login(String email, String password) async {
    final token = "demo-token-$email";
    await _storage.saveToken(token);
  }

  Future<void> register(String email, String password) async {
    final token = "demo-token-$email";
    await _storage.saveToken(token);
  }

  Future<String?> getToken() => _storage.getToken();

  Future<void> logout() => _storage.clear();
}
