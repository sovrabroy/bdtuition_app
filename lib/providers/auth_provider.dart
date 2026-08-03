import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/push_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _teacher;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  Map<String, dynamic>? get teacher => _teacher;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _api.isLoggedIn && _teacher != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _api.init();
  }

  Future<void> initialize() async {
    await _api.loadToken();
    final prefs = await SharedPreferences.getInstance();
    final teacherJson = prefs.getString('teacher_data');
    if (teacherJson != null && _api.isLoggedIn) {
      _teacher = json.decode(teacherJson);
      // Returning logged-in user: make sure the backend has this device's token.
      PushService.instance.registerWithBackendIfLoggedIn();
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String loginInput, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.login(loginInput, password);
      final data = response.data;

      if (data['success'] == true) {
        await _api.setToken(data['token']);
        _teacher = data['teacher'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('teacher_data', json.encode(_teacher));

        // Register this device for "nearby tuition" push notifications.
        PushService.instance.registerWithBackendIfLoggedIn();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> register(FormData formData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.register(formData);
      final data = response.data;

      _isLoading = false;
      notifyListeners();
      return data;
    } catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e);
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.verifyOTP(phoneNumber, code);
      final data = response.data;

      if (data['success'] == true) {
        await _api.setToken(data['token']);
        _teacher = data['teacher'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('teacher_data', json.encode(_teacher));

        // Register this device for "nearby tuition" push notifications.
        PushService.instance.registerWithBackendIfLoggedIn();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword({String? phone, String? email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.forgotPassword(
        phoneNumber: phone,
        email: email,
      );
      _isLoading = false;
      notifyListeners();
      return response.data['success'] == true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    String? phone,
    String? email,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.resetPassword(
        phoneNumber: phone,
        email: email,
        code: code,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return response.data['success'] == true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _api.clearToken();
    _teacher = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic e) {
  print("ERROR: $e");

  if (e is DioException) {
    print("STATUS: ${e.response?.statusCode}");
    print("BODY: ${e.response?.data}");

    if (e.response?.data is Map &&
        e.response!.data['message'] != null) {
      return e.response!.data['message'];
    }

    return e.message ?? "Network Error";
  }

  return e.toString();
}
}

