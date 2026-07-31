import 'check_in.dart';

/// A scheduled demo class for a tuition/guardian.
///
/// Everything here is stored locally on the device (no backend API yet).
/// The check-in list captures real GPS + device-verification data so a
/// teacher cannot falsely claim they attended a demo.
class DemoClass {
  final String id;
  final String tuitionCode;
  final String guardianName;
  final String address;

  /// Guardian location (destination) — used for distance + navigation.
  final double? guardianLat;
  final double? guardianLng;

  /// Scheduled demo start time.
  final DateTime scheduledAt;

  /// 'pending' | 'checked_in' | 'completed' | 'cancelled'
  String status;

  /// Check-in events recorded for this demo.
  final List<CheckIn> checkIns;

  DemoClass({
    required this.id,
    required this.tuitionCode,
    required this.guardianName,
    required this.address,
    this.guardianLat,
    this.guardianLng,
    required this.scheduledAt,
    this.status = 'pending',
    List<CheckIn>? checkIns,
  }) : checkIns = checkIns ?? [];

  bool get hasGuardianLocation => guardianLat != null && guardianLng != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tuition_code': tuitionCode,
        'guardian_name': guardianName,
        'address': address,
        'guardian_lat': guardianLat,
        'guardian_lng': guardianLng,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status,
        'check_ins': checkIns.map((c) => c.toJson()).toList(),
      };

  factory DemoClass.fromJson(Map<String, dynamic> json) => DemoClass(
        id: json['id'] as String,
        tuitionCode: json['tuition_code'] as String? ?? '',
        guardianName: json['guardian_name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        guardianLat: (json['guardian_lat'] as num?)?.toDouble(),
        guardianLng: (json['guardian_lng'] as num?)?.toDouble(),
        scheduledAt: DateTime.tryParse(json['scheduled_at'] as String? ?? '') ??
            DateTime.now(),
        status: json['status'] as String? ?? 'pending',
        checkIns: (json['check_ins'] as List?)
                ?.map((c) => CheckIn.fromJson(Map<String, dynamic>.from(c)))
                .toList() ??
            [],
      );
}
