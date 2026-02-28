import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _loading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> checkAuth() async {
    final token = await ApiService.getToken();
    _isAuthenticated = token != null;
    notifyListeners();
    return _isAuthenticated;
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password);
      if (result['success']) {
        final data = result['data'];
        await ApiService.saveToken(data['token']);
        _user = data['user'];
        _isAuthenticated = true;
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String username, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.signup(username, email, password);
      if (result['success']) {
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.deleteToken();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
