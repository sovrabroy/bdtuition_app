import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TeacherProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _profileData;
  List<dynamic> _guardians = [];
  List<dynamic> _reports = [];
  Map<String, dynamic>? _paymentsData;
  Map<String, dynamic>? _refundsData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  Map<String, dynamic>? get profileData => _profileData;
  List<dynamic> get guardians => _guardians;
  List<dynamic> get reports => _reports;
  Map<String, dynamic>? get paymentsData => _paymentsData;
  Map<String, dynamic>? get refundsData => _refundsData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.getDashboard();
      if (response.data['success'] == true) {
        _dashboardData = response.data['data'];
      }
    } catch (e) {
      _error = 'Failed to load dashboard';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.getProfile();
      if (response.data['success'] == true) {
        _profileData = response.data['data'];
      }
    } catch (e) {
      _error = 'Failed to load profile';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.updateProfile(data);
      if (response.data['success'] == true) {
        await loadProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      // Backend responded but success != true — surface its message.
      _error = response.data['message']?.toString() ?? 'Failed to update profile';
    } on DioException catch (e) {
      // Surface the real server error (validation, auth, etc.) instead of a
      // generic message, and log the body for debugging.
      // ignore: avoid_print
      print('updateProfile FAILED status=${e.response?.statusCode} body=${e.response?.data}');
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        _error = body['message'].toString();
      } else if (body is Map && body['errors'] is Map) {
        // Laravel validation errors: {"errors":{"field":["msg"]}}
        final firstField = (body['errors'] as Map).values.first;
        _error = firstField is List && firstField.isNotEmpty
            ? firstField.first.toString()
            : 'Validation failed';
      } else {
        _error = e.message ?? 'Failed to update profile';
      }
    } catch (e) {
      _error = 'Failed to update profile';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> loadGuardians() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.getGuardians();
      if (response.data['success'] == true) {
        _guardians = List.from(response.data['data']);
      }
    } catch (e) {
      _error = 'Failed to load guardians';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getGuardianDetails(int assignmentId) async {
    try {
      final response = await _api.getGuardianDetails(assignmentId);
      if (response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> revealGuardian(int assignmentId) async {
    try {
      final response = await _api.revealGuardian(assignmentId);
      return response.data;
    } catch (_) {}
    return null;
  }

  /// Triggers a masked call to the guardian via the backend (Issabel). The
  /// guardian's number never reaches the app. Returns the backend result map
  /// {success, message} — on success the teacher's phone will ring shortly.
  Future<Map<String, dynamic>> callGuardian(int assignmentId) async {
    try {
      final response = await _api.callGuardian(assignmentId);
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'success': false, 'message': 'Unexpected response.'};
    } catch (_) {
      return {
        'success': false,
        'message': 'Could not place the call. Please try again.',
      };
    }
  }

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.getReports();
      if (response.data['success'] == true) {
        _reports = List.from(response.data['data']);
      }
    } catch (e) {
      _error = 'Failed to load reports';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitReport(int assignmentId, String report) async {
    try {
      final response = await _api.submitReport(assignmentId, report);
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.getPayments();
      if (response.data['success'] == true) {
        _paymentsData = response.data['data'];
      }
    } catch (e) {
      _error = 'Failed to load payments';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> processPayment(int assignmentId, Map<String, dynamic> data) async {
    try {
      final response = await _api.processPayment(assignmentId, data);
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Starts an automatic bKash gateway payment. Asks the backend to create a
  /// bKash checkout session and returns the hosted `bkash_url` + `payment_id`
  /// so the UI can open it in a WebView. On failure returns a map with
  /// success=false and a message.
  Future<Map<String, dynamic>> createBkashPayment(
      int assignmentId, double amount) async {
    try {
      final response = await _api.createBkashPayment(assignmentId, amount);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return {
          'success': true,
          'bkash_url': data['bkash_url'],
          'payment_id': data['payment_id'],
        };
      }
      return {
        'success': false,
        'message': (data is Map ? data['message'] : null)?.toString() ??
            'Could not start bKash payment.',
      };
    } catch (e) {
      String msg = 'Could not start bKash payment. Please try again.';
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map && d['message'] != null) msg = d['message'].toString();
      }
      return {'success': false, 'message': msg};
    }
  }

  Future<void> loadRefunds() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.getRefunds();
      if (response.data['success'] == true) {
        _refundsData = response.data['data'];
      }
    } catch (e) {
      _error = 'Failed to load refunds';
    }

    _isLoading = false;
    notifyListeners();
  }
}
