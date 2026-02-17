import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _humanizeDioError(Object e) {
    if (e is! DioException) return e.toString();

    final data = e.response?.data;
    if (data is Map && data["detail"] != null) {
      return data["detail"].toString();
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return "Connection timeout. Please try again.";
    }

    if (e.type == DioExceptionType.connectionError) {
      return "Cannot connect to server. Check API URL / internet.";
    }

    final code = e.response?.statusCode;
    if (code != null) {
      if (code == 409) return "Username or email already exists";
      if (code == 401) return "Invalid email or password";
      if (code == 400) return "Bad request. Please check entered data.";
      return "Request failed ($code)";
    }

    return e.message ?? "Unknown network error";
  }

  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _token = await _auth.getToken();
    } catch (e) {
      _error = _humanizeDioError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String pass) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.login(email, pass);
      _token = await _auth.getToken();
      return isAuthed;
    } catch (e) {
      _error = _humanizeDioError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.register(username, email, password);
      _token = await _auth.getToken();
      return isAuthed;
    } catch (e) {
      _error = _humanizeDioError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.logout();
      _token = null;
    } catch (e) {
      _error = _humanizeDioError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
