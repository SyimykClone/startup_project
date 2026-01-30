import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthState extends ChangeNotifier {
  final AuthService _auth = AuthService();

  String? _token;
  bool _loading = false;

  String? get token => _token;
  bool get isLoading => _loading;
  bool get isAuthed => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    _token = await _auth.getToken();
    notifyListeners();
  }

  Future<void> login(String email, String pass) async {
    _loading = true;
    notifyListeners();
    await _auth.login(email, pass);
    _token = await _auth.getToken();
    _loading = false;
    notifyListeners();
  }

  Future<void> register(String email, String pass) async {
    _loading = true;
    notifyListeners();
    await _auth.register(email, pass);
    _token = await _auth.getToken();
    _loading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    _token = null;
    notifyListeners();
  }
}
