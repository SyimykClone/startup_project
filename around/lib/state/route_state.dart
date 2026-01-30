import 'package:flutter/material.dart';
import '../models/route_models.dart';

class RouteState extends ChangeNotifier {
  RouteResponse? _route;
  bool _loading = false;
  String? _error;

  RouteResponse? get route => _route;
  bool get loading => _loading;
  String? get error => _error;

  void start() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void setRoute(RouteResponse r) {
    _route = r;
    _loading = false;
    notifyListeners();
  }

  void fail(String msg) {
    _error = msg;
    _loading = false;
    notifyListeners();
  }

  void clear() {
    _route = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
