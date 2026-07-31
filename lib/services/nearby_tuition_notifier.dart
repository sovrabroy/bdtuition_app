import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Watches for newly-posted tuitions that fall inside the teacher's selected
/// "expected areas" and reports them so the UI can show an in-app popup.
///
/// This is the ONLINE / app-open half of the notification feature. It polls the
/// existing tuitions API on a timer — no backend change and no Firebase needed,
/// and it never fabricates data: if a poll fails or returns nothing new, no
/// notification is shown.
///
/// The OFFLINE / app-closed half (a system tray notification pushed while the
/// app isn't running) requires Firebase Cloud Messaging plus a cPanel backend
/// trigger. See NOTIFICATIONS_SETUP.md for that checklist.
class NearbyTuitionNotifier {
  NearbyTuitionNotifier._();
  static final NearbyTuitionNotifier instance = NearbyTuitionNotifier._();

  final ApiService _api = ApiService();
  Timer? _timer;

  /// IDs already surfaced to the teacher, so the same tuition isn't announced
  /// twice. Persisted so it survives app restarts.
  static const _kSeenKey = 'nearby_seen_tuition_ids';
  Set<int> _seen = {};

  /// How often to poll while the app is in the foreground.
  Duration pollInterval = const Duration(minutes: 3);

  /// UI hooks a callback here to render the popup. Receives the matching
  /// tuition map (raw API shape).
  void Function(Map<String, dynamic> tuition)? onMatch;

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final prefs = await SharedPreferences.getInstance();
    _seen = (prefs.getStringList(_kSeenKey) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    // First pass primes the "seen" set silently so existing tuitions don't all
    // fire at once on the very first launch.
    await _poll(firstRun: true);
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  /// Reads the teacher's expected areas from the saved profile.
  Future<List<String>> _expectedAreas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('teacher_data');
    if (raw == null) return const [];
    try {
      final data = json.decode(raw);
      if (data is! Map) return const [];
      final ea = data['expected_area'] ?? data['expected_areas'];
      if (ea is List) {
        return ea.map((e) => e.toString().trim().toLowerCase()).toList();
      }
      if (ea is String && ea.trim().isNotEmpty) {
        return ea
            .split(RegExp(r'[,;]'))
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> _poll({bool firstRun = false}) async {
    final areas = await _expectedAreas();
    if (areas.isEmpty) return; // Nothing selected → nothing to watch.

    List<dynamic> list;
    try {
      final response = await _api.getTuitions(page: 1);
      final data = response.data;
      if (data is! Map || data['success'] != true) return;
      list = data['data'] as List? ?? const [];
    } catch (_) {
      return; // Offline or error — stay silent, no fake alerts.
    }

    final prefs = await SharedPreferences.getInstance();
    var changed = false;

    for (final item in list) {
      if (item is! Map) continue;
      final t = Map<String, dynamic>.from(item);
      final id = t['id'];
      if (id is! int) continue;
      if (_seen.contains(id)) continue;

      final area = (t['area'] ?? t['location'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final matches =
          area.isNotEmpty && areas.any((a) => a == area || area.contains(a) || a.contains(area));

      // Mark every tuition we observe as seen so we only ever alert once.
      _seen.add(id);
      changed = true;

      if (matches && !firstRun) {
        onMatch?.call(t);
      }
    }

    if (changed) {
      // Cap stored history so the list doesn't grow unbounded.
      final trimmed = _seen.toList();
      if (trimmed.length > 500) {
        trimmed.removeRange(0, trimmed.length - 500);
        _seen = trimmed.toSet();
      }
      await prefs.setStringList(
          _kSeenKey, _seen.map((e) => e.toString()).toList());
    }
  }
}
