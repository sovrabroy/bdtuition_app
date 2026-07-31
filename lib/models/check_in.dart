/// A single check-in event captured when a teacher arrives for a demo.
///
/// Stores the REAL device data at the moment of check-in so it can be
/// audited later: GPS coordinates, distance from the guardian, and the
/// anti-fraud flags (mock GPS / rooted / developer mode). Nothing here is
/// hardcoded — every value comes from the device sensors/APIs.
class CheckIn {
  final String id;
  final DateTime time;

  /// Captured GPS at check-in.
  final double latitude;
  final double longitude;
  final double accuracy;

  /// Distance in metres from the guardian's location (null if unknown).
  final double? distanceFromGuardian;

  /// Optional selfie file path taken for live verification.
  final String? selfiePath;

  // --- Anti-fraud flags (true = suspicious) ---
  final bool isMockLocation;
  final bool isRooted;
  final bool isDeveloperMode;
  final bool isRealDevice;

  CheckIn({
    required this.id,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.distanceFromGuardian,
    this.selfiePath,
    this.isMockLocation = false,
    this.isRooted = false,
    this.isDeveloperMode = false,
    this.isRealDevice = true,
  });

  /// True when any anti-fraud flag is triggered.
  bool get isSuspicious =>
      isMockLocation || isRooted || isDeveloperMode || !isRealDevice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'distance_from_guardian': distanceFromGuardian,
        'selfie_path': selfiePath,
        'is_mock_location': isMockLocation,
        'is_rooted': isRooted,
        'is_developer_mode': isDeveloperMode,
        'is_real_device': isRealDevice,
      };

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        id: json['id'] as String,
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        distanceFromGuardian:
            (json['distance_from_guardian'] as num?)?.toDouble(),
        selfiePath: json['selfie_path'] as String?,
        isMockLocation: json['is_mock_location'] as bool? ?? false,
        isRooted: json['is_rooted'] as bool? ?? false,
        isDeveloperMode: json['is_developer_mode'] as bool? ?? false,
        isRealDevice: json['is_real_device'] as bool? ?? true,
      );
}
