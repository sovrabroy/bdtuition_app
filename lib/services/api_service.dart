import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _token;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired - clear and redirect to login
          clearToken();
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('teacher_data');
  }

  bool get isLoggedIn => _token != null;
  String? get token => _token;

  // ==================== AUTH ====================

  Future<Response> login(String login, String password) async {
    return await _dio.post(ApiConfig.login, data: {
      'login': login,
      'password': password,
    });
  }

  Future<Response> register(FormData formData) async {
    return await _dio.post(
      ApiConfig.register,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response> verifyOTP(String phoneNumber, String code) async {
    return await _dio.post(ApiConfig.verify, data: {
      'phone_number': phoneNumber,
      'verify_code': code,
    });
  }

  Future<Response> resendCode(String phoneNumber) async {
    return await _dio.post(ApiConfig.resendCode, data: {
      'phone_number': phoneNumber,
    });
  }

  Future<Response> forgotPassword(String phoneNumber) async {
    return await _dio.post(ApiConfig.forgotPassword, data: {
      'phone_number': phoneNumber,
    });
  }

  Future<Response> resetPassword(String phone, String code, String newPassword) async {
    return await _dio.post(ApiConfig.resetPassword, data: {
      'phone_number': phone,
      'verify_code': code,
      'new_password': newPassword,
    });
  }

  Future<Response> logout() async {
    return await _dio.post(ApiConfig.logout);
  }

  // ==================== DASHBOARD ====================

  Future<Response> getDashboard() async {
    return await _dio.get(ApiConfig.dashboard);
  }

  // ==================== PROFILE ====================

  Future<Response> getProfile() async {
    return await _dio.get(ApiConfig.profile);
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await _dio.put(ApiConfig.profile, data: data);
  }

  // ==================== TUITIONS ====================

  Future<Response> getTuitions({
    int page = 1,
    String? city,
    List<String>? area,
    String? gender,
    String? tuitionCode,
  }) async {
    Map<String, dynamic> params = {'page': page};
    if (city != null) params['city'] = city;
    if (area != null && area.isNotEmpty) params['area'] = area;
    if (gender != null) params['gender'] = gender;
    if (tuitionCode != null) params['tuition_code'] = tuitionCode;
    return await _dio.get(ApiConfig.tuitions, queryParameters: params);
  }

  Future<Response> getTuitionDetails(int id) async {
    return await _dio.get('${ApiConfig.tuitions}/$id');
  }

  Future<Response> applyForTuition(int tuitionId, String authorityReference) async {
    return await _dio.post('${ApiConfig.tuitions}/$tuitionId/apply', data: {
      'authority_reference': authorityReference,
    });
  }

  Future<Response> getCities() async {
    return await _dio.get(ApiConfig.cities);
  }

  Future<Response> getAreas(String city) async {
    return await _dio.get(ApiConfig.areas, queryParameters: {'city': city});
  }

  // ==================== GUARDIANS ====================

  Future<Response> getGuardians() async {
    return await _dio.get(ApiConfig.guardians);
  }

  Future<Response> getGuardianDetails(int assignmentId) async {
    return await _dio.get('${ApiConfig.guardians}/$assignmentId');
  }

  Future<Response> revealGuardian(int assignmentId) async {
    return await _dio.post('${ApiConfig.guardians}/$assignmentId/reveal');
  }

  // ==================== REPORTS ====================

  Future<Response> getReports() async {
    return await _dio.get(ApiConfig.reports);
  }

  Future<Response> submitReport(int assignmentId, String report) async {
    return await _dio.post(ApiConfig.reports, data: {
      'assignment_id': assignmentId,
      'report': report,
    });
  }

  // ==================== PAYMENTS ====================

  Future<Response> getPayments() async {
    return await _dio.get(ApiConfig.payments);
  }

  Future<Response> processPayment(int assignmentId, Map<String, dynamic> data) async {
    return await _dio.post('${ApiConfig.payments}/$assignmentId/process', data: data);
  }

  Future<Response> getPaymentReceipt(int paymentId) async {
    return await _dio.get('${ApiConfig.payments}/receipt/$paymentId');
  }

  Future<Response> createBkashPayment(int assignmentId, double amount) async {
    return await _dio.post('${ApiConfig.payments}/bkash/$assignmentId', data: {
      'amount': amount,
    });
  }

  // ==================== REFUNDS ====================

  Future<Response> getRefunds() async {
    return await _dio.get(ApiConfig.refunds);
  }

  Future<Response> processRefund(int assignmentId, Map<String, dynamic> data) async {
    return await _dio.post('${ApiConfig.refunds}/$assignmentId', data: data);
  }
}
