import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthState extends ChangeNotifier {
  final AuthService _auth;

  AuthState(this._auth);

  String? _token;
  bool _loading = false;
  String? _error;

  String? get token => _token;
  bool get isLoading => _loading;
  bool get isAuthed => _token != null && _token!.isNotEmpty;
  String? get error => _error;

  Future<void> init() async {
    _token = await _auth.getToken();
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> login(String email, String pass) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.login(email, pass);
      _token = await _auth.getToken();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.register(username, email, password);
      _token = await _auth.getToken();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    _token = null;
    notifyListeners();
  }
}
