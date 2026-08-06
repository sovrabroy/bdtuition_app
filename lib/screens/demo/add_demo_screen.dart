import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/demo_class.dart';
import '../../providers/demo_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../services/security_service.dart';
import '../../services/api_service.dart';

class AddDemoScreen extends StatefulWidget {
  const AddDemoScreen({super.key});

  @override
  State<AddDemoScreen> createState() => _AddDemoScreenState();
}

class _AddDemoScreenState extends State<AddDemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final ApiService _api = ApiService();

  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  double? _guardianLat;
  double? _guardianLng;
  bool _pinning = false;
  bool _saving = false;
  bool _looking = false;
  // Set once a lookup succeeds so the "copy code" affordance can appear.
  bool _codeResolved = false;

  // ---- Approved-tuition dropdown state ----
  // Approved/assigned guardians (each has a tuition_code) that the teacher can
  // pick from instead of typing a code by hand. Populated from /guardians.
  bool _loadingApproved = false;
  List<Map<String, dynamic>> _approved = [];
  String? _selectedCode;

  // Teacher's live GPS — pinned by the teacher (not guardian).
  double? _teacherLat;
  double? _teacherLng;

  // Backend tuition id resolved from the selected/looked-up code. Needed so the
  // server can pull the guardian's phone + address and send the OTP.
  int? _tuitionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApproved());
  }

  /// Loads the teacher's approved/assigned guardians so their tuition codes can
  /// be offered in the dropdown. Only tuitions the admin has approved appear.
  Future<void> _loadApproved() async {
    setState(() => _loadingApproved = true);
    try {
      final provider = Provider.of<TeacherProvider>(context, listen: false);
      await provider.loadGuardians();
      final list = provider.guardians
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((g) => _pick(g, ['tuition_code']).isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() => _approved = list);
    } catch (_) {
      // Silent — the manual code field still works if this fails.
    } finally {
      if (mounted) setState(() => _loadingApproved = false);
    }
  }

  /// Tolerant multi-key lookup: returns the first non-empty value among [keys].
  String _pick(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty &&
          v.toString().trim().toLowerCase() != 'null') {
        return v.toString().trim();
      }
    }
    return '';
  }

  double? _pickDouble(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final d = v is num ? v.toDouble() : double.tryParse(v.toString());
      if (d != null) return d;
    }
    return null;
  }

  /// Fills guardian name / address / location from an approved guardian record.
  /// Pulls the richer detail record when an assignment id is available so we
  /// get the full address (and coordinates, if the backend stores them).
  Future<void> _applyApprovedCode(String code) async {
    final match = _approved.firstWhere(
      (g) => _pick(g, ['tuition_code']) == code,
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) return;

    setState(() {
      _selectedCode = code;
      _codeCtrl.text = code;
      _codeResolved = true;
    });

    // Seed from the summary record immediately.
    _fillFromGuardian(match);

    // Then try the detail endpoint for a fuller address / coordinates.
    final assignmentId = match['assignment_id'] ?? match['id'];
    if (assignmentId is int || (assignmentId is String && int.tryParse(assignmentId) != null)) {
      final id = assignmentId is int ? assignmentId : int.parse(assignmentId);
      setState(() => _looking = true);
      try {
        final provider = Provider.of<TeacherProvider>(context, listen: false);
        final details = await provider.getGuardianDetails(id);
        if (details != null && mounted) _fillFromGuardian(details);
      } catch (_) {
        // Keep the summary values already filled in.
      } finally {
        if (mounted) setState(() => _looking = false);
      }
    }

    // Make sure we have the backend tuition id (the OTP flow needs it). If the
    // guardian record didn't carry one, resolve it from the code via /tuitions.
    if (_tuitionId == null) await _resolveTuitionId(code);
  }

  /// Silently resolves the backend tuition id for [code] via /tuitions so the
  /// server can pull the guardian phone + address when scheduling.
  Future<void> _resolveTuitionId(String code) async {
    try {
      final response = await _api.getTuitions(tuitionCode: code);
      final data = response.data;
      final list = (data is Map && data['success'] == true)
          ? (data['data'] as List? ?? [])
          : const [];
      if (list.isEmpty) return;
      final t = Map<String, dynamic>.from(list.first as Map);
      final tid = _pickDouble(t, ['tuition_id', 'id'])?.toInt();
      if (tid != null && mounted) setState(() => _tuitionId = tid);
    } catch (_) {
      // Non-fatal — save will warn if we still have no tuition id.
    }
  }

  /// Applies address / coordinates from a guardian map. Guardian name is NOT
  /// stored locally — the server pulls it from the tuition record when sending
  /// the OTP.
  void _fillFromGuardian(Map<String, dynamic> g) {
    final address = _pick(g, ['address', 'full_address', 'tuition_address']);
    final area = _pick(g, ['area', 'location']);
    final city = _pick(g, ['city', 'district']);
    final lat = _pickDouble(g, ['guardian_lat', 'lat', 'latitude']);
    final lng = _pickDouble(g, ['guardian_lng', 'lng', 'longitude']);
    final tid = _pickDouble(g, ['tuition_id'])?.toInt();

    setState(() {
      if (tid != null) _tuitionId = tid;
      if (address.isNotEmpty) {
        _addressCtrl.text = address;
      } else if (area.isNotEmpty || city.isNotEmpty) {
        _addressCtrl.text = [area, city].where((s) => s.isNotEmpty).join(', ');
      }
      if (lat != null && lng != null) {
        _guardianLat = lat;
        _guardianLng = lng;
      }
    });
  }

  /// Manual lookup (typed code) — kept as a fallback for codes not in the
  /// approved list. Nothing is faked: unknown codes just report "not found".
  Future<void> _lookupCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a tuition code first.')),
      );
      return;
    }
    setState(() => _looking = true);
    try {
      final response = await _api.getTuitions(tuitionCode: code);
      final data = response.data;
      final list = (data is Map && data['success'] == true)
          ? (data['data'] as List? ?? [])
          : const [];
      if (list.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No tuition found for code "$code".')),
        );
        return;
      }
      final t = Map<String, dynamic>.from(list.first as Map);
      if (!mounted) return;
      // In a tuition record, `id` is the tuition id the server needs.
      final tid = _pickDouble(t, ['tuition_id', 'id'])?.toInt();
      setState(() {
        _codeResolved = true;
        if (tid != null) _tuitionId = tid;
      });
      _fillFromGuardian(t);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tuition details imported.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lookup failed. Check your connection.')),
        );
      }
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  Future<void> _copyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied "$code" to clipboard.')),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
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

  /// Pins the TEACHER's own live GPS. The guardian's address comes from the
  /// selected tuition code — the teacher only needs to mark where THEY are so
  /// "Open in Maps" can draw the route (and Maps shows the real road distance).
  Future<void> _pinCurrentLocation() async {
    setState(() => _pinning = true);
    try {
      final pos = await SecurityService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _teacherLat = pos.latitude;
        _teacherLng = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your location pinned.')),
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
  /// Opens Google Maps directions from the teacher's pinned location (origin)
  /// to the guardian's location — pinned coordinates if we have them, else the
  /// typed address. Lets the teacher see the real route & travel distance.
  Future<void> _openDirections() async {
    // Destination: prefer exact coordinates, fall back to the address text.
    final String destination;
    if (_guardianLat != null && _guardianLng != null) {
      destination = '$_guardianLat,$_guardianLng';
    } else if (_addressCtrl.text.trim().isNotEmpty) {
      destination = _addressCtrl.text.trim();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No guardian location or address yet.')),
      );
      return;
    }

    final params = <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    };
    // Origin is optional — if we have the teacher's GPS, use it so the route
    // starts exactly from the teacher. Otherwise Maps uses the device location.
    if (_teacherLat != null && _teacherLng != null) {
      params['origin'] = '$_teacherLat,$_teacherLng';
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', params);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // The OTP flow is server-backed and needs the backend tuition id so it can
    // reach the guardian's phone. Block save (with a clear message) if missing.
    if (_tuitionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not resolve this tuition on the server. Pick an approved '
              'code or import a valid code before saving.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    // Destination for distance checks: prefer the guardian's pinned coordinates,
    // otherwise fall back to where the teacher pinned themselves at the address.
    final destLat = _guardianLat ?? _teacherLat;
    final destLng = _guardianLng ?? _teacherLng;

    final demo = DemoClass(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tuitionId: _tuitionId,
      tuitionCode: _codeCtrl.text.trim(),
      guardianName: '',
      address: _addressCtrl.text.trim(),
      guardianLat: destLat,
      guardianLng: destLng,
      teacherLat: _teacherLat,
      teacherLng: _teacherLng,
      scheduledAt: _scheduledAt,
    );

    final provider = Provider.of<DemoProvider>(context, listen: false);

    // Register on the backend first so the OTP can be scheduled. Only persist
    // locally once we have the server id, so the dashboard can open OTP verify.
    final ok = await provider.scheduleOnServer(demo);
    if (!ok) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.lastError ?? 'Could not save demo.')),
      );
      return;
    }

    await provider.addDemo(demo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Demo scheduled. An OTP has been sent to the guardian now. '
            'Collect it from them when you reach their home to verify.'),
      ),
    );
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
            // ---- Approved tuition code dropdown ----
            // Only tuitions the admin approved show up here. Picking one fills
            // the code + guardian name + address automatically.
            _ApprovedCodeDropdown(
              loading: _loadingApproved,
              approved: _approved,
              selected: _selectedCode,
              codeOf: (g) => _pick(g, ['tuition_code']),
              labelOf: (g) {
                final code = _pick(g, ['tuition_code']);
                final area = _pick(g, ['area', 'location']);
                final city = _pick(g, ['city', 'district']);
                final where =
                    [area, city].where((s) => s.isNotEmpty).join(', ');
                return where.isEmpty ? code : '$code — $where';
              },
              onRefresh: _loadApproved,
              onChanged: (code) {
                if (code != null) _applyApprovedCode(code);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _codeCtrl,
              decoration: InputDecoration(
                labelText: 'Tuition Code',
                helperText:
                    'Pick an approved code above, or type one and import.',
                prefixIcon: const Icon(Icons.tag),
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_codeResolved)
                      IconButton(
                        tooltip: 'Copy code',
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: _copyCode,
                      ),
                    _looking
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Import details from code',
                            icon: const Icon(Icons.download_for_offline),
                            onPressed: _lookupCode,
                          ),
                  ],
                ),
              ),
              onFieldSubmitted: (_) => _lookupCode(),
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
                      const Text('Your Location',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _teacherLat != null
                        ? 'Pinned: ${_teacherLat!.toStringAsFixed(5)}, ${_teacherLng!.toStringAsFixed(5)}'
                        : 'Pin where you are now so the route to the guardian '
                            'starts from your exact spot.',
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
                    label: Text(_teacherLat != null
                        ? 'Re-pin at current location'
                        : 'Pin at current location'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---- Route & distance via Google Maps ----
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.directions, size: 20),
                      SizedBox(width: 8),
                      Text('Route to Guardian',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Opens Google Maps with the full route and real travel '
                    'distance from your pinned location to the guardian address.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Open in Google Maps'),
                    ),
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

/// Dropdown of the teacher's approved tuition codes. Shows a friendly empty /
/// loading state so it never looks broken when there are no approvals yet.
class _ApprovedCodeDropdown extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> approved;
  final String? selected;
  final String Function(Map<String, dynamic>) codeOf;
  final String Function(Map<String, dynamic>) labelOf;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onChanged;

  const _ApprovedCodeDropdown({
    required this.loading,
    required this.approved,
    required this.selected,
    required this.codeOf,
    required this.labelOf,
    required this.onRefresh,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Approved Tuition Code',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Refresh',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: onRefresh,
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (!loading && approved.isEmpty)
            const Text(
              'No approved tuitions yet. Once the admin approves your '
              'application, its code will appear here.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            )
          else
            DropdownButtonFormField<String>(
              value: selected,
              isExpanded: true,
              hint: const Text('Select an approved code'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              items: approved
                  .map((g) => codeOf(g))
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .map((code) {
                final g = approved.firstWhere((e) => codeOf(e) == code);
                return DropdownMenuItem(value: code, child: Text(labelOf(g)));
              }).toList(),
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}
