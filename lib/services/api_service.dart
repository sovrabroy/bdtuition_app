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

  /// Requests a password-reset code. Pass the identifier the teacher chose to
  /// use — either their phone number or their email. The backend accepts
  /// whichever key is present and sends the code over that channel.
  Future<Response> forgotPassword({String? phoneNumber, String? email}) async {
    final data = <String, dynamic>{};
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      data['phone_number'] = phoneNumber.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }
    return await _dio.post(ApiConfig.forgotPassword, data: data);
  }

  /// Confirms the reset. Send back the same identifier used to request the code
  /// (phone OR email) plus the verification code and the new password.
  Future<Response> resetPassword({
    String? phoneNumber,
    String? email,
    required String code,
    required String newPassword,
  }) async {
    final data = <String, dynamic>{
      'verify_code': code,
      'new_password': newPassword,
    };
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      data['phone_number'] = phoneNumber.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }
    return await _dio.post(ApiConfig.resetPassword, data: data);
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

  /// Masked click-to-call. The backend looks up the guardian's number
  /// server-side and asks Issabel (Asterisk) to originate a bridged call:
  /// the teacher's own phone rings first, and on answer it connects to the
  /// guardian. The guardian's number is NEVER returned to the app, so the
  /// teacher can talk to the guardian without ever seeing their number.
  Future<Response> callGuardian(int assignmentId) async {
    return await _dio.post(ApiConfig.guardianCall(assignmentId));
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

  // ==================== PUSH NOTIFICATIONS ====================

  /// Registers this device's FCM token with the backend so the server can push
  /// "new tuition near you" notifications while the app is closed. Backend
  /// endpoint (POST /fcm-token) is documented in NOTIFICATIONS_SETUP.md.
  Future<Response> registerFcmToken(String token) async {
    return await _dio.post(ApiConfig.fcmToken, data: {'token': token});
  }

  // ==================== DEMO VERIFICATION (OTP anti-fraud) ====================

  /// Teacher's own scheduled demos (server-side). Backend GET /demo.
  Future<Response> getDemos() async {
    return await _dio.get(ApiConfig.demos);
  }

  /// Schedule a demo. The backend pulls the guardian's phone + address from the
  /// tuition record itself (so the teacher can't fake them) and later auto-sends
  /// the OTP 2 hours before [scheduledAt] via cron.
  Future<Response> scheduleDemo({
    int? tuitionId,
    int? assignmentId,
    required DateTime scheduledAt,
    double? guardianLat,
    double? guardianLng,
  }) async {
    final data = <String, dynamic>{
      'scheduled_at': scheduledAt.toIso8601String(),
    };
    if (tuitionId != null) data['tuition_id'] = tuitionId;
    if (assignmentId != null) data['assignment_id'] = assignmentId;
    if (guardianLat != null) data['guardian_lat'] = guardianLat;
    if (guardianLng != null) data['guardian_lng'] = guardianLng;
    return await _dio.post(ApiConfig.demoSchedule, data: data);
  }

  /// Teacher pastes the OTP the guardian gave them, together with their own live
  /// GPS + device-integrity flags. The server checks the code and records where
  /// the teacher actually was (distance from the guardian address) so a remote
  /// paste / fake location is caught.
  Future<Response> verifyDemoOtp({
    required int demoId,
    required String otp,
    required double lat,
    required double lng,
    bool isMock = false,
    bool isRooted = false,
  }) async {
    return await _dio.post(ApiConfig.demoVerifyOtp(demoId), data: {
      'otp': otp,
      'lat': lat,
      'lng': lng,
      'is_mock': isMock,
      'is_rooted': isRooted,
    });
  }

  /// Ask the backend to send a fresh OTP to the guardian's phone.
  Future<Response> resendDemoOtp(int demoId) async {
    return await _dio.post(ApiConfig.demoResendOtp(demoId));
  }

  /// Report the teacher's current location to the rolling 30-day log. Called
  /// when the app is used (app open / opening the demo screen / OTP verify),
  /// not as continuous background tracking.
  Future<Response> logLocation({
    int? tuitionId,
    required double lat,
    required double lng,
    double? accuracy,
    bool isMock = false,
    bool isRooted = false,
    String context = 'app_open',
  }) async {
    final data = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'is_mock': isMock,
      'is_rooted': isRooted,
      'context': context,
    };
    if (tuitionId != null) data['tuition_id'] = tuitionId;
    if (accuracy != null) data['accuracy'] = accuracy;
    return await _dio.post(ApiConfig.locationLog, data: data);
  }
}
