import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/demo_class.dart';
import '../models/check_in.dart';

/// Persists demo classes + their check-ins locally on the device using
/// SharedPreferences. This is the "offline" store — when a backend API is
/// added later, this same data can be synced up.
class DemoStorage {
  static const String _key = 'demo_classes_v1';

  /// Load all demos (newest scheduled first).
  Future<List<DemoClass>> loadDemos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final demos = list
          .map((e) => DemoClass.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      demos.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return demos;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<DemoClass> demos) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(demos.map((d) => d.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> addDemo(DemoClass demo) async {
    final demos = await loadDemos();
    demos.add(demo);
    await _saveAll(demos);
  }

  Future<void> updateDemo(DemoClass demo) async {
    final demos = await loadDemos();
    final idx = demos.indexWhere((d) => d.id == demo.id);
    if (idx >= 0) {
      demos[idx] = demo;
    } else {
      demos.add(demo);
    }
    await _saveAll(demos);
  }

  Future<void> deleteDemo(String id) async {
    final demos = await loadDemos();
    demos.removeWhere((d) => d.id == id);
    await _saveAll(demos);
  }

  /// Append a check-in to a demo and persist.
  Future<void> addCheckIn(String demoId, CheckIn checkIn) async {
    final demos = await loadDemos();
    final idx = demos.indexWhere((d) => d.id == demoId);
    if (idx < 0) return;
    demos[idx].checkIns.add(checkIn);
    demos[idx].status = 'checked_in';
    await _saveAll(demos);
  }

  /// Flat list of every check-in across all demos (newest first) — used by
  /// the Check-In History / attendance log screen.
  Future<List<MapEntry<DemoClass, CheckIn>>> loadAllCheckIns() async {
    final demos = await loadDemos();
    final entries = <MapEntry<DemoClass, CheckIn>>[];
    for (final d in demos) {
      for (final c in d.checkIns) {
        entries.add(MapEntry(d, c));
      }
    }
    entries.sort((a, b) => b.value.time.compareTo(a.value.time));
    return entries;
  }
}
