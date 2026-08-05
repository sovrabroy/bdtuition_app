import 'check_in.dart';

/// A scheduled demo class for a tuition/guardian.
///
/// Everything here is stored locally on the device (no backend API yet).
/// The check-in list captures real GPS + device-verification data so a
/// teacher cannot falsely claim they attended a demo.
class DemoClass {
  final String id;

  /// Server-side demo_schedules.id once this demo has been scheduled on the
  /// backend. Null until the schedule call succeeds. Used to run OTP verify.
  int? serverId;

  /// Backend tuition id (tuitions.id) this demo belongs to. Lets us tag
  /// location logs so the admin can count visits near this tuition's address.
  final int? tuitionId;

  final String tuitionCode;
  final String guardianName;
  final String address;

  /// 'not_sent' | 'otp_sent' | 'verified' — mirrors the server demo status so
  /// the UI can show whether the OTP has been sent / the demo verified.
  String otpStatus;

  /// Guardian location (destination) — used for distance + navigation.
  final double? guardianLat;
  final double? guardianLng;

  /// Teacher's own location at the moment they scheduled the demo. Stored so
  /// the admin can see where the teacher was when they created the schedule.
  final double? teacherLat;
  final double? teacherLng;

  /// Free-text notes the teacher can edit (e.g. "guardian changed the time",
  /// "address hard to find"). Synced to the backend.
  String notes;

  /// Scheduled demo start time.
  final DateTime scheduledAt;

  /// 'pending' | 'checked_in' | 'completed' | 'cancelled'
  String status;

  /// Check-in events recorded for this demo.
  final List<CheckIn> checkIns;

  DemoClass({
    required this.id,
    this.serverId,
    this.tuitionId,
    required this.tuitionCode,
    required this.guardianName,
    required this.address,
    this.guardianLat,
    this.guardianLng,
    this.teacherLat,
    this.teacherLng,
    this.notes = '',
    required this.scheduledAt,
    this.status = 'pending',
    this.otpStatus = 'not_sent',
    List<CheckIn>? checkIns,
  }) : checkIns = checkIns ?? [];

  bool get hasGuardianLocation => guardianLat != null && guardianLng != null;

  // ---------------------------------------------------------------------------
  // Anti-fraud "genuine visit" logic.
  //
  // Purpose: prove how many times a teacher REALLY went to this address in the
  // last 30 days. If a teacher later lies ("I don't teach this tuition") to
  // avoid paying media fee, this record is the proof.
  //
  // A check-in counts as a genuine visit only when:
  //   1. No fraud flag was raised (not mock GPS / root / dev-mode / emulator).
  //   2. It happened within [geofenceRadiusMeters] of the guardian's locked
  //      location (when that location is known).
  // ---------------------------------------------------------------------------

  /// How close (metres) a check-in must be to the guardian's pinned location
  /// to count as "at the address".
  static const double geofenceRadiusMeters = 200;

  /// We only keep / count the last 30 days of visit data.
  static const int windowDays = 30;

  bool isGenuineVisit(CheckIn c) {
    if (c.isSuspicious) return false;
    if (hasGuardianLocation) {
      final d = c.distanceFromGuardian;
      if (d == null) return false;
      return d <= geofenceRadiusMeters;
    }
    // No reference location pinned — fall back to device-integrity only.
    return true;
  }

  /// Genuine check-ins that happened within the last [windowDays] days.
  List<CheckIn> get genuineVisits {
    final cutoff = DateTime.now().subtract(const Duration(days: windowDays));
    return checkIns
        .where((c) => isGenuineVisit(c) && c.time.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  /// Number of *distinct days* the teacher genuinely visited in the last 30
  /// days (multiple check-ins on the same day count once).
  int get genuineVisitDays {
    final days = genuineVisits
        .map((c) => DateTime(c.time.year, c.time.month, c.time.day))
        .toSet();
    return days.length;
  }

  DateTime? get firstGenuineVisit {
    final v = genuineVisits;
    if (v.isEmpty) return null;
    return v.map((c) => c.time).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime? get lastGenuineVisit {
    final v = genuineVisits;
    if (v.isEmpty) return null;
    return v.map((c) => c.time).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'server_id': serverId,
        'tuition_id': tuitionId,
        'tuition_code': tuitionCode,
        'guardian_name': guardianName,
        'address': address,
        'guardian_lat': guardianLat,
        'guardian_lng': guardianLng,
        'teacher_lat': teacherLat,
        'teacher_lng': teacherLng,
        'notes': notes,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status,
        'otp_status': otpStatus,
        'check_ins': checkIns.map((c) => c.toJson()).toList(),
      };

  factory DemoClass.fromJson(Map<String, dynamic> json) => DemoClass(
        id: json['id'] as String,
        serverId: (json['server_id'] as num?)?.toInt(),
        tuitionId: (json['tuition_id'] as num?)?.toInt(),
        tuitionCode: json['tuition_code'] as String? ?? '',
        guardianName: json['guardian_name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        guardianLat: (json['guardian_lat'] as num?)?.toDouble(),
        guardianLng: (json['guardian_lng'] as num?)?.toDouble(),
        teacherLat: (json['teacher_lat'] as num?)?.toDouble(),
        teacherLng: (json['teacher_lng'] as num?)?.toDouble(),
        notes: json['notes'] as String? ?? '',
        scheduledAt: DateTime.tryParse(json['scheduled_at'] as String? ?? '') ??
            DateTime.now(),
        status: json['status'] as String? ?? 'pending',
        otpStatus: json['otp_status'] as String? ?? 'not_sent',
        checkIns: (json['check_ins'] as List?)
                ?.map((c) => CheckIn.fromJson(Map<String, dynamic>.from(c)))
                .toList() ??
            [],
      );
}
