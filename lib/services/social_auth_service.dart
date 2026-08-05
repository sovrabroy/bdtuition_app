import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around the Google + Facebook SDKs. It only obtains the
/// provider token (ID token for Google, access token for Facebook) — the
/// backend does the real verification and login. Returns null when the user
/// cancels, or throws a readable message on error.
class SocialAuthService {
  // The Web client ID (client_type 3 from google-services.json). Required as
  // serverClientId so Android returns an idToken whose `aud` the backend can
  // verify. Without this, auth.idToken is usually null on Android.
  static const String _webClientId =
      '98555773695-gkt2o9q59nsjqjlhgj5octi199tv2b0n.apps.googleusercontent.com';

  static final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _webClientId,
  );

  /// Signs in with Google and returns the ID token, or null if cancelled.
  static Future<String?> googleIdToken() async {
    // Sign out first so the account chooser always shows (avoids silently
    // reusing a stale account).
    await _google.signOut();

    final account = await _google.signIn();
    if (account == null) return null; // user cancelled

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw 'Could not get Google credentials. Please try again.';
    }
    return idToken;
  }

  /// Signs in with Facebook and returns the access token, or null if cancelled.
  static Future<String?> facebookAccessToken() async {
    final result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );

    switch (result.status) {
      case LoginStatus.success:
        final token = result.accessToken?.tokenString;
        if (token == null || token.isEmpty) {
          throw 'Could not get Facebook credentials. Please try again.';
        }
        return token;
      case LoginStatus.cancelled:
        return null;
      case LoginStatus.failed:
      case LoginStatus.operationInProgress:
        throw result.message ?? 'Facebook sign-in failed. Please try again.';
    }
  }

  /// Clears any cached social session (called on logout).
  static Future<void> signOutAll() async {
    try {
      await _google.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
