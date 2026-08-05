import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/social_auth_service.dart';
import '../screens/dashboard/home_screen.dart';
import '../screens/auth/register_screen.dart';

/// Google + Facebook sign-in buttons plus a divider. Drop this into the login
/// or welcome screen. Handles the whole flow: obtain provider token → backend
/// login → either go to Home (existing account) or open registration prefilled
/// (new account).
class SocialLoginButtons extends StatefulWidget {
  const SocialLoginButtons({super.key});

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  bool _busy = false;

  Future<void> _google() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final idToken = await SocialAuthService.googleIdToken();
      if (idToken == null) {
        // Cancelled.
        if (mounted) setState(() => _busy = false);
        return;
      }
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final result = await auth.loginWithGoogle(idToken);
      if (!mounted) return;
      _route(result);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _facebook() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final token = await SocialAuthService.facebookAccessToken();
      if (token == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final result = await auth.loginWithFacebook(token);
      if (!mounted) return;
      _route(result);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Routes based on the backend result: logged-in → Home; new user → open
  /// registration prefilled; otherwise show the error.
  void _route(Map<String, dynamic> result) {
    if (result['loggedIn'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    if (result['newUser'] == true) {
      final prefill = Map<String, dynamic>.from(result['prefill'] ?? {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Almost there! Please complete your registration to finish.',
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterScreen(
            prefillName: prefill['teacher_name']?.toString(),
            prefillEmail: prefill['email']?.toString(),
          ),
        ),
      );
      return;
    }

    _showError(result['error']?.toString() ?? 'Sign-in failed');
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // "or continue with" divider
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or continue with',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(),
          )
        else
          Row(
            children: [
              // Google
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _google,
                  icon: const Icon(Icons.g_mobiledata, size: 28,
                      color: Color(0xFFDB4437)),
                  label: const Text('Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Facebook
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _facebook,
                  icon: const Icon(Icons.facebook, size: 22,
                      color: Color(0xFF1877F2)),
                  label: const Text('Facebook'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
