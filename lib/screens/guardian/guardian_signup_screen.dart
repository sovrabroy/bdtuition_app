import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/guardian_provider.dart';
import 'guardian_home_screen.dart';

/// Guardian signup ("Sign Up as Guardian"). Wired to the live register API.
/// Creates the account; the guardian can then submit a tutor request from
/// inside the panel (Apply for Tutor).
class GuardianSignupScreen extends StatefulWidget {
  const GuardianSignupScreen({super.key});

  @override
  State<GuardianSignupScreen> createState() => _GuardianSignupScreenState();
}

class _GuardianSignupScreenState extends State<GuardianSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _city = 'Dhaka';
  bool _obscure = true;

  static const _cities = ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final guardian = Provider.of<GuardianProvider>(context, listen: false);
    final ok = await guardian.register({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'city': _city,
      'area': _areaCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    });

    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GuardianHomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(guardian.error ?? 'Registration failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up as Guardian')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel('Your Details'),
                _field(_nameCtrl, 'Full Name', Icons.person_outline),
                _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                    keyboard: TextInputType.phone),
                _field(_emailCtrl, 'Email (optional)', Icons.email_outlined,
                    required: false, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 8),

                _sectionLabel('Password'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 4
                        ? 'At least 4 characters'
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) =>
                        v != _passwordCtrl.text ? 'Passwords do not match' : null,
                  ),
                ),
                const SizedBox(height: 8),

                _sectionLabel('Location'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _city,
                    decoration: const InputDecoration(labelText: 'City'),
                    items: _cities
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _city = v ?? _city),
                  ),
                ),
                _field(_areaCtrl, 'Area', Icons.map_outlined, required: false),
                _field(_addressCtrl, 'Full Address', Icons.place_outlined,
                    required: false),
                const SizedBox(height: 24),

                Consumer<GuardianProvider>(
                  builder: (context, guardian, _) {
                    return ElevatedButton(
                      onPressed: guardian.isLoading ? null : _handleSignup,
                      child: guardian.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create Account'),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = true,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }
}
