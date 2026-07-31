import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/guardian_provider.dart';

/// Guardian applies for a tutor — submits a tutor request to the backend
/// (guardian_tutor_requests). New request, no existing pipeline touched.
class GuardianApplyScreen extends StatefulWidget {
  const GuardianApplyScreen({super.key});

  @override
  State<GuardianApplyScreen> createState() => _GuardianApplyScreenState();
}

class _GuardianApplyScreenState extends State<GuardianApplyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _classCtrl = TextEditingController();
  final _subjectsCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _city = 'Dhaka';
  String _tutorGender = 'Any';
  bool _submitting = false;

  static const _cities = ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna'];
  static const _genders = ['Any', 'Male', 'Female'];

  @override
  void dispose() {
    _classCtrl.dispose();
    _subjectsCtrl.dispose();
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    _budgetCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final guardian = Provider.of<GuardianProvider>(context, listen: false);
    final res = await guardian.applyForTutor({
      'student_class': _classCtrl.text.trim(),
      'subjects': _subjectsCtrl.text.trim(),
      'city': _city,
      'area': _areaCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'preferred_tutor_gender': _tutorGender,
      'budget': _budgetCtrl.text.trim(),
      'note': _noteCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    final ok = res['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ??
            (ok ? 'Request submitted' : 'Failed to submit')),
        backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for a Tutor')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tell us what you need. Our team will find a matching tutor '
                  'and contact you.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                _field(_classCtrl, 'Student Class / Level', Icons.school_outlined),
                _field(_subjectsCtrl, 'Subjects Needed', Icons.menu_book_outlined),
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
                _field(_areaCtrl, 'Area', Icons.map_outlined),
                _field(_addressCtrl, 'Full Address', Icons.place_outlined,
                    required: false),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _tutorGender,
                    decoration:
                        const InputDecoration(labelText: 'Preferred Tutor Gender'),
                    items: _genders
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _tutorGender = v ?? _tutorGender),
                  ),
                ),
                _field(_budgetCtrl, 'Monthly Budget (৳)', Icons.attach_money,
                    required: false, keyboard: TextInputType.number),
                _field(_noteCtrl, 'Extra Note (optional)', Icons.notes,
                    required: false, maxLines: 3),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = true,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
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
