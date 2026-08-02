import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'security_service.dart';

/// Sends the teacher's location to the backend rolling 30-day log when the app
/// is *used* — not as continuous background tracking. Over time this builds a
/// picture of how often the teacher was near each tuition address, which the
/// admin panel uses to spot fraud.
///
/// Every call is best-effort and completely silent: if the teacher isn't logged
/// in, location is off, or permission hasn't been granted yet, we just skip.
/// We never pop a permission dialog from here — that would be jarring on a plain
/// app open. Permission is requested in the flows that genuinely need it (pin
/// location, OTP verify); once granted, these background logs start flowing.
class LocationLogger {
  static final ApiService _api = ApiService();

  /// Log the current location. [tuitionId] tags the ping to a tuition so the
  /// server can compute distance from that address. [context] is a short label
  /// (e.g. 'app_open', 'demo_screen') stored alongside the row.
  static Future<void> log({int? tuitionId, String context = 'app_open'}) async {
    try {
      if (!_api.isLoggedIn) return;

      // Only proceed if location services are on AND permission is already
      // granted — never prompt from a passive log.
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final report =
          await SecurityService.checkDevice(positionIsMocked: pos.isMocked);

      await _api.logLocation(
        tuitionId: tuitionId,
        lat: pos.latitude,
        lng: pos.longitude,
        accuracy: pos.accuracy,
        isMock: report.isMockLocation,
        isRooted: report.isRooted,
        context: context,
      );
    } catch (_) {
      // Best-effort: a failed log must never disrupt the app.
    }
  }
}
