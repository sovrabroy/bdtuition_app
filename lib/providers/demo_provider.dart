import 'package:flutter/material.dart';
import '../models/demo_class.dart';
import '../models/check_in.dart';
import '../services/demo_storage.dart';
import '../services/api_service.dart';
import '../services/security_service.dart';

/// Holds demo classes + check-ins and persists them via [DemoStorage].
class DemoProvider with ChangeNotifier {
  final DemoStorage _storage = DemoStorage();
  final ApiService _api = ApiService();

  List<DemoClass> _demos = [];
  bool _isLoading = false;

  List<DemoClass> get demos => _demos;
  bool get isLoading => _isLoading;

  /// Demos that are still upcoming or in progress (not completed/cancelled).
  List<DemoClass> get activeDemos => _demos
      .where((d) => d.status == 'pending' || d.status == 'checked_in')
      .toList();

  List<DemoClass> get completedDemos =>
      _demos.where((d) => d.status == 'completed').toList();

  int get totalCheckIns =>
      _demos.fold(0, (sum, d) => sum + d.checkIns.length);

  int get suspiciousCheckIns => _demos.fold(
      0,
      (sum, d) =>
          sum + d.checkIns.where((c) => c.isSuspicious).length);

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _demos = await _storage.loadDemos();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDemo(DemoClass demo) async {
    await _storage.addDemo(demo);
    await load();
  }

  // ==================== SERVER-BACKED DEMO VERIFICATION ====================
  // Everything below talks to the backend so the admin panel can audit for
  // fraud. Local storage is still used to render the dashboard nicely, but the
  // server is the source of truth for OTP + location proof.

  String? _lastError;
  String? get lastError => _lastError;

  /// Schedules [demo] on the backend and stores the returned server demo id on
  /// the local record (so we can later run OTP verify). Returns true on success.
  Future<bool> scheduleOnServer(DemoClass demo) async {
    _lastError = null;
    try {
      final res = await _api.scheduleDemo(
        tuitionId: demo.tuitionId,
        scheduledAt: demo.scheduledAt,
        guardianLat: demo.guardianLat,
        guardianLng: demo.guardianLng,
      );
      final data = res.data;
      if (data is Map && data['success'] == true) {
        final sid = (data['demo_id'] as num?)?.toInt();
        if (sid != null) {
          demo.serverId = sid;
          demo.otpStatus = 'not_sent';
          await _storage.updateDemo(demo);
        }
        return true;
      }
      _lastError = (data is Map ? data['message'] : null)?.toString() ??
          'Could not schedule the demo.';
      return false;
    } catch (e) {
      _lastError = 'Network error while scheduling. Please try again.';
      return false;
    }
  }

  /// Verifies the OTP the guardian gave the teacher, sending the teacher's live
  /// GPS + device-integrity flags. On success marks the local demo verified.
  /// Returns a result map: {success, message, distance_m}.
  Future<Map<String, dynamic>> verifyOtp(DemoClass demo, String otp) async {
    _lastError = null;
    if (demo.serverId == null) {
      return {'success': false, 'message': 'This demo is not on the server yet.'};
    }
    try {
      // Live GPS (throws a readable message if GPS is off / denied).
      final pos = await SecurityService.getCurrentPosition();
      final report =
          await SecurityService.checkDevice(positionIsMocked: pos.isMocked);

      final res = await _api.verifyDemoOtp(
        demoId: demo.serverId!,
        otp: otp.trim(),
        lat: pos.latitude,
        lng: pos.longitude,
        isMock: report.isMockLocation,
        isRooted: report.isRooted,
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['success'] == true) {
        demo.otpStatus = 'verified';
        demo.status = 'checked_in';
        await _storage.updateDemo(demo);
        await load();
      }
      return data;
    } catch (e) {
      final msg = e is String ? e : 'Verification failed. Please try again.';
      return {'success': false, 'message': msg};
    }
  }

  /// Asks the backend to send a fresh OTP to the guardian's phone.
  Future<bool> resendOtp(DemoClass demo) async {
    if (demo.serverId == null) return false;
    try {
      final res = await _api.resendDemoOtp(demo.serverId!);
      final data = res.data;
      if (data is Map && data['success'] == true) {
        demo.otpStatus = 'otp_sent';
        await _storage.updateDemo(demo);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateDemo(DemoClass demo) async {
    await _storage.updateDemo(demo);
    await load();
  }

  Future<void> deleteDemo(String id) async {
    await _storage.deleteDemo(id);
    await load();
  }

  Future<void> addCheckIn(String demoId, CheckIn checkIn) async {
    await _storage.addCheckIn(demoId, checkIn);
    await load();
  }

  Future<void> completeDemo(String demoId) async {
    final idx = _demos.indexWhere((d) => d.id == demoId);
    if (idx < 0) return;
    _demos[idx].status = 'completed';
    await _storage.updateDemo(_demos[idx]);
    await load();
  }
}
