import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import 'package:dio/dio.dart';

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

  Future<void> register(
    String username,
    String email,
    String password, {
    String userType = 'user',
  }) async {
    final res = await api.dio.post('/api/auth/register', data: {
      "username": username,
      "email": email,
      "password": password,
      "user_type": userType,
    });

    final token = res.data['access_token'] as String;
    await _storage.saveToken(token);
    api.setToken(token);
  }

  Future<void> loginWithGoogle(String idToken) async {
    final res = await api.dio.post('/api/auth/google', data: {
      "id_token": idToken,
    });

    final token = res.data['access_token'] as String;
    await _storage.saveToken(token);
    api.setToken(token);
  }

  Future<void> resetPassword(String email, String newPassword) async {
    await api.dio.post('/api/auth/reset-password', data: {
      "email": email,
      "new_password": newPassword,
    });
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final res = await api.dio.get('/api/auth/me');
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateMe({
    String? username,
    String? currentPassword,
    String? password,
    String? avatarFilePath,
  }) async {
    final form = FormData();
    if (username != null && username.trim().isNotEmpty) {
      form.fields.add(MapEntry("username", username.trim()));
    }
    if (password != null && password.trim().isNotEmpty) {
      if (currentPassword != null && currentPassword.trim().isNotEmpty) {
        form.fields.add(MapEntry("current_password", currentPassword.trim()));
      }
      form.fields.add(MapEntry("password", password.trim()));
    }
    if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
      final fileName = avatarFilePath.split(RegExp(r"[\\/]+")).last;
      form.files.add(
        MapEntry(
          "avatar",
          await MultipartFile.fromFile(avatarFilePath, filename: fileName),
        ),
      );
    }

    final res = await api.dio.patch('/api/auth/me', data: form);
    return (res.data as Map).cast<String, dynamic>();
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
