import 'package:flutter/material.dart';
import '../models/demo_class.dart';
import '../models/check_in.dart';
import '../services/demo_storage.dart';

/// Holds demo classes + check-ins and persists them via [DemoStorage].
class DemoProvider with ChangeNotifier {
  final DemoStorage _storage = DemoStorage();

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
