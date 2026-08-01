import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _ResetMethod { phone, email }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _codeSent = false;
  _ResetMethod _method = _ResetMethod.phone;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  bool get _usingPhone => _method == _ResetMethod.phone;

  /// The identifier the teacher entered for the chosen method.
  String get _identifier =>
      _usingPhone ? _phoneCtrl.text.trim() : _emailCtrl.text.trim();

  Future<void> _sendCode() async {
    if (_identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_usingPhone
              ? 'Enter your phone number first.'
              : 'Enter your email first.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.forgotPassword(
      phone: _usingPhone ? _identifier : null,
      email: _usingPhone ? null : _identifier,
    );
    if (!mounted) return;
    if (success) {
      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_usingPhone
              ? 'Reset code sent to your phone!'
              : 'Reset code sent to your email!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (_codeCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resetPassword(
      phone: _usingPhone ? _identifier : null,
      email: _usingPhone ? null : _identifier,
      code: _codeCtrl.text.trim(),
      newPassword: _newPassCtrl.text,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated! Please login.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Method toggle — phone vs email. Locked once a code is sent so the
            // teacher can't switch channel mid-flow (the code belongs to one).
            SegmentedButton<_ResetMethod>(
              segments: const [
                ButtonSegment(
                  value: _ResetMethod.phone,
                  label: Text('Phone'),
                  icon: Icon(Icons.phone),
                ),
                ButtonSegment(
                  value: _ResetMethod.email,
                  label: Text('Email'),
                  icon: Icon(Icons.email),
                ),
              ],
              selected: {_method},
              onSelectionChanged: _codeSent
                  ? null
                  : (s) => setState(() => _method = s.first),
            ),
            const SizedBox(height: 20),
            if (_usingPhone)
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                enabled: !_codeSent,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              )
            else
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !_codeSent,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            const SizedBox(height: 16),
            if (!_codeSent)
              ElevatedButton(
                onPressed: _sendCode,
                child: const Text('Send Reset Code'),
              ),
            if (_codeSent) ...[
              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _resetPassword,
                child: const Text('Reset Password'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _codeSent = false;
                  _codeCtrl.clear();
                  _newPassCtrl.clear();
                }),
                child: const Text('Use a different phone / email'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
