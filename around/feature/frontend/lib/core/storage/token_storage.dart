import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _key = "auth_token";

  Future<void> saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, token);
  }

  Future<String?> getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_key);
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
