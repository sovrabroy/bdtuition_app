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

  // Demo verification (OTP anti-fraud). Everything is stored server-side so the
  // admin panel can audit; nothing is device-only.
  static const String demos = '/demo'; // GET list, POST /demo/schedule
  static const String demoSchedule = '/demo/schedule';
  // Per-demo actions take the server demo id: /demo/{id}/verify-otp etc.
  static String demoVerifyOtp(int id) => '/demo/$id/verify-otp';
  static String demoResendOtp(int id) => '/demo/$id/resend-otp';

  // Rolling teacher location log (sent when the app is used, not in background).
  static const String locationLog = '/location/log';

  /// Resolve a photo/document path returned by the API into a full URL.
  /// Handles: already-absolute URLs, paths that already include "uploads/",
  /// and bare filenames (which get the teacher-documents base prefixed).
  /// Returns null when there is nothing usable to show.
  static String? resolveImageUrl(dynamic path) {
    if (path == null) return null;
    var p = path.toString().trim();
    if (p.isEmpty || p.toLowerCase() == 'null') return null;

    // Already a full URL.
    if (p.startsWith('http://') || p.startsWith('https://')) return p;

    // Normalise leading slashes.
    while (p.startsWith('/')) {
      p = p.substring(1);
    }

    // Path already rooted at the site's uploads folder.
    if (p.startsWith('uploads/')) {
      return 'https://manage.bdtuition.com/$p';
    }

    // Bare filename or teachers-documents relative path.
    return '$imageBaseUrl$p';
  }
}
