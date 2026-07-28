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
        return true;
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
