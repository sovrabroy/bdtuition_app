import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/guardian_api_service.dart';

/// State for the guardian side: auth session + the guardian's assigned
/// teachers, tutor requests, and reviews. Mirrors the teacher AuthProvider
/// so behaviour is predictable, but is fully independent of it.
class GuardianProvider with ChangeNotifier {
  final GuardianApiService _api = GuardianApiService();

  Map<String, dynamic>? _guardian;
  List<dynamic> _teachers = [];
  bool _isLoading = false;
  bool _teachersLoading = false;
  String? _error;
  bool _isInitialized = false;

  Map<String, dynamic>? get guardian => _guardian;
  List<dynamic> get teachers => _teachers;
  bool get isLoading => _isLoading;
  bool get teachersLoading => _teachersLoading;
  String? get error => _error;
  bool get isLoggedIn => _api.isLoggedIn && _guardian != null;
  bool get isInitialized => _isInitialized;

  GuardianProvider() {
    _api.init();
  }

  Future<void> initialize() async {
    await _api.loadToken();
    final prefs = await SharedPreferences.getInstance();
    final gJson = prefs.getString('guardian_data');
    if (gJson != null && _api.isLoggedIn) {
      _guardian = json.decode(gJson);
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String loginInput, String password) async {
    _setLoading(true);
    try {
      final res = await _api.login(loginInput, password);
      final data = res.data;
      if (data['success'] == true) {
        await _persistSession(data);
        _setLoading(false);
        return true;
      }
      _error = data['message'] ?? 'Login failed';
      _setLoading(false);
      return false;
    } catch (e) {
      _error = _errorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> form) async {
    _setLoading(true);
    try {
      final res = await _api.register(form);
      final data = res.data;
      if (data['success'] == true) {
        await _persistSession(data);
        _setLoading(false);
        return true;
      }
      _error = data['message'] ?? 'Registration failed';
      _setLoading(false);
      return false;
    } catch (e) {
      _error = _errorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadMyTeachers() async {
    _teachersLoading = true;
    notifyListeners();
    try {
      final res = await _api.getMyTeachers();
      final data = res.data;
      if (data['success'] == true) {
        _teachers = (data['teachers'] as List?) ?? [];
        _error = null;
      } else {
        _error = data['message'];
      }
    } catch (e) {
      _error = _errorMessage(e);
    }
    _teachersLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> applyForTutor(Map<String, dynamic> form) async {
    try {
      final res = await _api.applyForTutor(form);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      return {'success': false, 'message': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> submitReview(Map<String, dynamic> form) async {
    try {
      final res = await _api.submitReview(form);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      return {'success': false, 'message': _errorMessage(e)};
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _api.clearToken();
    _guardian = null;
    _teachers = [];
    notifyListeners();
  }

  // ---- helpers ----

  Future<void> _persistSession(Map<String, dynamic> data) async {
    await _api.setToken(data['token']);
    _guardian = data['guardian'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guardian_data', json.encode(_guardian));
    _error = null;
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  String _errorMessage(dynamic e) {
    if (e is DioException) {
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        return e.response!.data['message'];
      }
      return e.message ?? 'Network error';
    }
    return e.toString();
  }
}
