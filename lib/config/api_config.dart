class ApiConfig {
  static const String baseUrl = 'https://panel.bdtuition.com/api';
  static const String imageBaseUrl = 'https://manage.bdtuition.com/uploads/teachers-documents/';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verify = '/auth/verify';
  static const String resendCode = '/auth/resend-code';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Profile
  static const String profile = '/profile';

  // Tuitions
  static const String tuitions = '/tuitions';
  static const String cities = '/tuitions/cities';
  static const String areas = '/tuitions/areas';
  static const String tuitionCount = '/tuitions/count';

  // Guardians
  static const String guardians = '/guardians';

  // Reports
  static const String reports = '/reports';

  // Payments
  static const String payments = '/payments';

  // Refunds
  static const String refunds = '/refunds';

  // Verification
  static const String verificationPayment = '/verification/payment';

  // FCM
  static const String fcmToken = '/fcm-token';
}
