import 'package:flutter/material.dart';
import '../models/poi.dart';

class PoiState extends ChangeNotifier {
  List<Poi> _poi = [];
  bool _loading = false;
  String? _error;

  List<Poi> get poi => _poi;
  bool get loading => _loading;
  String? get error => _error;

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void setPoi(List<Poi> list) {
    _poi = list;
    notifyListeners();
  }

  void setError(String? e) {
    _error = e;
    notifyListeners();
  }
}
