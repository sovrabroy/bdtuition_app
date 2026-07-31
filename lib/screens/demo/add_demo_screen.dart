import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/demo_class.dart';
import '../../providers/demo_provider.dart';
import '../../services/security_service.dart';

class AddDemoScreen extends StatefulWidget {
  const AddDemoScreen({super.key});

  @override
  State<AddDemoScreen> createState() => _AddDemoScreenState();
}

class _AddDemoScreenState extends State<AddDemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _guardianCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  double? _guardianLat;
  double? _guardianLng;
  bool _pinning = false;
  bool _saving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _guardianCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pinCurrentLocation() async {
    setState(() => _pinning = true);
    try {
      final pos = await SecurityService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _guardianLat = pos.latitude;
        _guardianLng = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardian location pinned.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _pinning = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final demo = DemoClass(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tuitionCode: _codeCtrl.text.trim(),
      guardianName: _guardianCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      guardianLat: _guardianLat,
      guardianLng: _guardianLng,
      scheduledAt: _scheduledAt,
    );

    await Provider.of<DemoProvider>(context, listen: false).addDemo(demo);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dt = _scheduledAt;
    final dateLabel =
        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('New Demo Class')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Tuition Code',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _guardianCtrl,
              decoration: const InputDecoration(
                labelText: 'Guardian Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.place),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.black26),
              ),
              leading: const Icon(Icons.schedule),
              title: const Text('Scheduled At'),
              subtitle: Text(dateLabel),
              trailing: const Icon(Icons.edit),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, size: 20),
                      const SizedBox(width: 8),
                      const Text('Guardian Location',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _guardianLat != null
                        ? 'Pinned: ${_guardianLat!.toStringAsFixed(5)}, ${_guardianLng!.toStringAsFixed(5)}'
                        : 'Optional — enables distance check & navigation.',
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pinning ? null : _pinCurrentLocation,
                    icon: _pinning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.gps_fixed, size: 18),
                    label: Text(_guardianLat != null
                        ? 'Re-pin at current location'
                        : 'Pin at current location'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Demo', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
