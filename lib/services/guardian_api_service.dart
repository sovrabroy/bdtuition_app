import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Network layer for the guardian side.
///
/// Kept separate from the teacher [ApiService] so a guardian session and a
/// teacher session never clash: the guardian token lives under its own
/// SharedPreferences key. Talks to the same host (panel.bdtuition.com) where
/// the new guardian endpoints live.
class GuardianApiService {
  static final GuardianApiService _instance = GuardianApiService._internal();
  factory GuardianApiService() => _instance;
  GuardianApiService._internal();

  static const _tokenKey = 'guardian_auth_token';

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
          clearToken();
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('guardian_data');
  }

  bool get isLoggedIn => _token != null;
  String? get token => _token;

  // ==================== AUTH ====================

  Future<Response> register(Map<String, dynamic> data) {
    return _dio.post('/guardian/register', data: data);
  }

  Future<Response> login(String login, String password) {
    return _dio.post('/guardian/login', data: {
      'login': login,
      'password': password,
    });
  }

  Future<Response> logout() => _dio.post('/guardian/logout');

  Future<Response> getProfile() => _dio.get('/guardian/profile');

  // ==================== DATA ====================

  Future<Response> getMyTeachers() => _dio.get('/guardian/teachers');

  Future<Response> applyForTutor(Map<String, dynamic> data) {
    return _dio.post('/guardian/apply', data: data);
  }

  Future<Response> getMyRequests() => _dio.get('/guardian/requests');

  Future<Response> submitReview(Map<String, dynamic> data) {
    return _dio.post('/guardian/review', data: data);
  }

  Future<Response> getMyReviews() => _dio.get('/guardian/reviews');
}
