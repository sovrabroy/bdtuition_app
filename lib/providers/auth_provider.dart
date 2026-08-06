import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/push_service.dart';
import '../services/activity_service.dart';
import '../services/social_auth_service.dart';

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
      // Report a one-time install for teachers who were already logged in when
      // this build first shipped the feature (they'd otherwise never trigger it).
      ActivityService.instance.reportInstallOnce();
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
        // Open a foreground activity session now that we're logged in (the app
        // is already resumed, so the lifecycle observer won't fire on its own).
        ActivityService.instance.startSession();

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

  /// Completes a social login once the app has obtained a provider token.
  /// Pass the raw backend response data. If it's a login (`new_user:false`),
  /// stores the token + teacher and returns {loggedIn:true}. If it's a new
  /// user, returns {loggedIn:false, newUser:true, prefill:{...}} so the caller
  /// can open registration prefilled. On failure returns {error:...}.
  Future<Map<String, dynamic>> _handleSocialResponse(
      Map<String, dynamic> data) async {
    if (data['success'] != true) {
      _error = data['message']?.toString() ?? 'Sign-in failed';
      return {'loggedIn': false, 'error': _error};
    }

    // Existing account → real login.
    if (data['new_user'] == false && data['token'] != null) {
      await _api.setToken(data['token']);
      _teacher = data['teacher'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('teacher_data', json.encode(_teacher));
      PushService.instance.registerWithBackendIfLoggedIn();
      ActivityService.instance.startSession();
      notifyListeners();
      return {'loggedIn': true};
    }

    // No account yet → app should open registration prefilled.
    return {
      'loggedIn': false,
      'newUser': true,
      'prefill': Map<String, dynamic>.from(data['prefill'] ?? {}),
      'provider': data['provider'],
    };
  }

  /// Google: exchange an already-obtained Google ID token with the backend.
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.googleLogin(idToken);
      final result = await _handleSocialResponse(
          Map<String, dynamic>.from(response.data));
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return {'loggedIn': false, 'error': _error};
    }
  }

  /// Facebook: exchange an already-obtained FB access token with the backend.
  Future<Map<String, dynamic>> loginWithFacebook(String accessToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.facebookLogin(accessToken);
      final result = await _handleSocialResponse(
          Map<String, dynamic>.from(response.data));
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return {'loggedIn': false, 'error': _error};
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
        // Open a foreground activity session now that we're logged in (the app
        // is already resumed, so the lifecycle observer won't fire on its own).
        ActivityService.instance.startSession();

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
    // Close the activity session while the token is still valid, so the end
    // ping (with its duration) can be attributed to this teacher.
    await ActivityService.instance.endSession();
    try {
      await _api.logout();
    } catch (_) {}
    // Also clear any Google/Facebook session so the next social sign-in shows
    // the account chooser instead of silently reusing the old account.
    await SocialAuthService.signOutAll();
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

