import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _codeSent = false;

  Future<void> _sendCode() async {
    if (_phoneCtrl.text.isEmpty) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.forgotPassword(_phoneCtrl.text.trim());
    if (!mounted) return;
    if (success) {
      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset code sent!'), backgroundColor: AppTheme.successColor),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (_codeCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resetPassword(_phoneCtrl.text.trim(), _codeCtrl.text, _newPassCtrl.text);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated! Please login.'), backgroundColor: AppTheme.successColor),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed'), backgroundColor: AppTheme.errorColor),
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
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              enabled: !_codeSent,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 16),
            if (!_codeSent)
              ElevatedButton(onPressed: _sendCode, child: const Text('Send Reset Code')),
            if (_codeSent) ...[
              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Verification Code', counterText: ''),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _resetPassword, child: const Text('Reset Password')),
            ],
          ],
        ),
      ),
    );
  }
}
