import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';

/// Result of a full device + location security check performed at check-in.
class SecurityReport {
  final bool isMockLocation;
  final bool isRooted;
  final bool isDeveloperMode;
  final bool isRealDevice;

  const SecurityReport({
    required this.isMockLocation,
    required this.isRooted,
    required this.isDeveloperMode,
    required this.isRealDevice,
  });

  /// Any red flag → the check-in is untrustworthy.
  bool get isSuspicious =>
      isMockLocation || isRooted || isDeveloperMode || !isRealDevice;

  /// Human readable list of triggered flags.
  List<String> get flags {
    final f = <String>[];
    if (isMockLocation) f.add('Mock/Fake GPS detected');
    if (isRooted) f.add('Rooted device');
    if (isDeveloperMode) f.add('Developer mode enabled');
    if (!isRealDevice) f.add('Emulator / not a real device');
    return f;
  }
}

/// Runs anti-fraud checks so a teacher cannot fake their attendance/location.
///
/// Every value is read live from the device — nothing is simulated.
class SecurityService {
  /// Detect root, developer mode and emulator via safe_device.
  /// Each check is guarded so one failing plugin call doesn't block the rest.
  static Future<SecurityReport> checkDevice({bool positionIsMocked = false}) async {
    bool rooted = false;
    bool devMode = false;
    bool realDevice = true;
    bool safeMock = false;

    try {
      rooted = await SafeDevice.isJailBroken;
    } catch (_) {}
    try {
      devMode = await SafeDevice.isDevelopmentModeEnable;
    } catch (_) {}
    try {
      realDevice = await SafeDevice.isRealDevice;
    } catch (_) {}
    try {
      safeMock = await SafeDevice.isMockLocation;
    } catch (_) {}

    return SecurityReport(
      // Trust either the OS position flag OR safe_device's own mock check.
      isMockLocation: positionIsMocked || safeMock,
      isRooted: rooted,
      isDeveloperMode: devMode,
      isRealDevice: realDevice,
    );
  }

  /// Ensure location services are on and permission is granted, then return
  /// a fresh high-accuracy fix. Throws a readable message on failure.
  static Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are turned off. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. Enable it from Settings.';
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  /// Distance in metres between two coordinates.
  static double distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
