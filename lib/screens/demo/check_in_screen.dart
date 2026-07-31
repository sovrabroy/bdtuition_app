import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../models/check_in.dart';
import '../../models/demo_class.dart';
import '../../providers/demo_provider.dart';
import '../../services/security_service.dart';

class CheckInScreen extends StatefulWidget {
  final DemoClass demo;
  const CheckInScreen({super.key, required this.demo});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _capturing = false;
  String? _error;

  Position? _position;
  double? _distance;
  SecurityReport? _report;
  String? _selfiePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    setState(() {
      _capturing = true;
      _error = null;
    });
    try {
      final pos = await SecurityService.getCurrentPosition();
      final report = await SecurityService.checkDevice(
        positionIsMocked: pos.isMocked,
      );

      double? dist;
      if (widget.demo.guardianLat != null &&
          widget.demo.guardianLng != null) {
        dist = SecurityService.distanceBetween(
          pos.latitude,
          pos.longitude,
          widget.demo.guardianLat!,
          widget.demo.guardianLng!,
        );
      }

      if (!mounted) return;
      setState(() {
        _position = pos;
        _report = report;
        _distance = dist;
        _capturing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _capturing = false;
      });
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
      );
      if (img != null && mounted) {
        setState(() => _selfiePath = img.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _confirmCheckIn() async {
    final pos = _position;
    final report = _report;
    if (pos == null || report == null) return;

    final checkIn = CheckIn(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: DateTime.now(),
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      distanceFromGuardian: _distance,
      selfiePath: _selfiePath,
      isMockLocation: report.isMockLocation,
      isRooted: report.isRooted,
      isDeveloperMode: report.isDeveloperMode,
      isRealDevice: report.isRealDevice,
    );

    await Provider.of<DemoProvider>(context, listen: false)
        .addCheckIn(widget.demo.id, checkIn);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          checkIn.isSuspicious
              ? 'Checked in — but flagged as suspicious.'
              : 'Check-in recorded successfully.',
        ),
        backgroundColor:
            checkIn.isSuspicious ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check In')),
      body: _capturing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Capturing GPS & verifying device...'),
                ],
              ),
            )
          : _error != null
              ? _errorView()
              : _resultView(),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off,
                size: 56, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _capture,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultView() {
    final pos = _position!;
    final report = _report!;
    final suspicious = report.isSuspicious;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Demo target
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.demo.guardianName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(widget.demo.address,
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Security verdict banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (suspicious ? AppTheme.errorColor : AppTheme.successColor)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  (suspicious ? AppTheme.errorColor : AppTheme.successColor)
                      .withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                suspicious ? Icons.gpp_bad : Icons.verified_user,
                color:
                    suspicious ? AppTheme.errorColor : AppTheme.successColor,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suspicious
                      ? 'Device verification FAILED. This check-in will be flagged.'
                      : 'Device verified. GPS looks genuine.',
                  style: TextStyle(
                    color: suspicious
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _infoTile(Icons.my_location, 'Coordinates',
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}'),
        _infoTile(Icons.gps_fixed, 'GPS Accuracy',
            '±${pos.accuracy.toStringAsFixed(1)} m'),
        if (_distance != null)
          _infoTile(
            Icons.straighten,
            'Distance from Guardian',
            _distance! < 1000
                ? '${_distance!.toStringAsFixed(0)} m'
                : '${(_distance! / 1000).toStringAsFixed(2)} km',
            highlight: _distance! > 200,
          ),

        const SizedBox(height: 12),
        const Text('Security Checks',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _checkTile('Mock / Fake GPS', report.isMockLocation),
        _checkTile('Rooted Device', report.isRooted),
        _checkTile('Developer Mode', report.isDeveloperMode),
        _checkTile('Emulator (not real device)', !report.isRealDevice),

        const SizedBox(height: 20),
        const Text('Selfie Verification (optional)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_selfiePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_selfiePath!),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _takeSelfie,
          icon: const Icon(Icons.camera_alt),
          label: Text(_selfiePath == null ? 'Take Selfie' : 'Retake Selfie'),
        ),

        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  suspicious ? AppTheme.errorColor : AppTheme.successColor,
            ),
            onPressed: _confirmCheckIn,
            icon: const Icon(Icons.check),
            label: Text(
              suspicious ? 'Check In Anyway (Flagged)' : 'Confirm Check-In',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _capture,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Recapture GPS'),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black45),
          const SizedBox(width: 10),
          Text('$label:', style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: highlight ? AppTheme.warningColor : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkTile(String label, bool bad) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            bad ? Icons.cancel : Icons.check_circle,
            color: bad ? AppTheme.errorColor : AppTheme.successColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(label),
          const Spacer(),
          Text(
            bad ? 'DETECTED' : 'OK',
            style: TextStyle(
              color: bad ? AppTheme.errorColor : AppTheme.successColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
