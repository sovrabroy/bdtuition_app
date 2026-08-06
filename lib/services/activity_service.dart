import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Tracks two things the admin "Teacher Activity" page needs but that can't be
/// derived from the API traffic alone:
///
///   1. How long the teacher actually keeps the app in the foreground — a
///      "session" that starts when the app is resumed (or right after login)
///      and ends when it goes to the background / the teacher logs out.
///   2. A one-time "install" event, fired the first time a logged-in teacher
///      opens this install of the app, so the admin can see when the app first
///      landed on their phone.
///
/// Uninstall is deliberately NOT handled here: Android gives an app no callback
/// when it is being removed. The backend infers uninstall separately, from FCM
/// push tokens that come back as NotRegistered.
///
/// Everything here is best-effort and silent. A failed report must never affect
/// the teacher's experience, so every network call is wrapped and swallowed.
class ActivityService {
  ActivityService._();
  static final ActivityService instance = ActivityService._();

  final ApiService _api = ApiService();

  static const _kInstallReportedKey = 'activity_install_reported';

  /// Opaque token identifying the CURRENT foreground session. The backend keys
  /// its session row on this so a `start` and its matching `end` update the same
  /// row (duration filled in on end). Null when no session is open.
  String? _sessionToken;
  DateTime? _sessionStart;

  /// True while a session is open, so repeated `resumed` events (which Android
  /// can deliver more than once) don't stack up multiple sessions.
  bool get hasOpenSession => _sessionToken != null;

  /// Begin a foreground session. Safe to call on every `resumed` lifecycle event
  /// and right after login — if a session is already open it's a no-op. Skips
  /// entirely when the teacher isn't logged in (no token to attribute it to).
  Future<void> startSession() async {
    if (!_api.isLoggedIn) return;
    if (_sessionToken != null) return;

    final token = _generateToken();
    _sessionToken = token;
    _sessionStart = DateTime.now();

    try {
      await _api.logAppSession(action: 'start', sessionToken: token);
    } catch (e) {
      // Keep the session open locally even if the start ping failed; the end
      // ping still carries the duration so the row can be created then.
      debugPrint('ActivityService.startSession skipped: $e');
    }
  }

  /// End the current foreground session, reporting how many seconds it lasted.
  /// Safe to call on `paused` / `detached` and from logout; a no-op when no
  /// session is open. Clears local session state either way.
  Future<void> endSession() async {
    final token = _sessionToken;
    final start = _sessionStart;
    _sessionToken = null;
    _sessionStart = null;
    if (token == null) return;

    final seconds =
        start == null ? 0 : DateTime.now().difference(start).inSeconds;

    try {
      // Attribute the session even if the teacher logged out a moment ago: the
      // backend accepts the still-valid token on `_api` at logout time. If the
      // token is already gone we simply skip.
      if (!_api.isLoggedIn) return;
      await _api.logAppSession(
        action: 'end',
        sessionToken: token,
        durationSeconds: seconds,
      );
    } catch (e) {
      debugPrint('ActivityService.endSession skipped: $e');
    }
  }

  /// Fire the install event exactly once per install of the app. Guarded by a
  /// SharedPreferences flag so it only ever sends the first time a logged-in
  /// teacher opens the app; subsequent launches are no-ops. If the send fails
  /// the flag is NOT set, so it retries on the next launch.
  Future<void> reportInstallOnce() async {
    if (!_api.isLoggedIn) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kInstallReportedKey) == true) return;

      await _api.logAppEvent('install');
      await prefs.setBool(_kInstallReportedKey, true);
    } catch (e) {
      debugPrint('ActivityService.reportInstallOnce skipped: $e');
    }
  }

  /// Random URL-safe token for a session. Doesn't need to be cryptographically
  /// strong — it only has to be unique enough to pair a start with its end.
  String _generateToken() {
    final rnd = Random();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final salt = rnd.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '${ts.toRadixString(16)}$salt';
  }
}
