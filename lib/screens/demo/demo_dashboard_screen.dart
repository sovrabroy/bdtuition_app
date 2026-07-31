import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/demo_class.dart';
import '../../providers/demo_provider.dart';
import 'add_demo_screen.dart';
import 'check_in_screen.dart';
import 'checkin_history_screen.dart';
import 'visit_proof_screen.dart';

class DemoDashboardScreen extends StatefulWidget {
  const DemoDashboardScreen({super.key});

  @override
  State<DemoDashboardScreen> createState() => _DemoDashboardScreenState();
}

class _DemoDashboardScreenState extends State<DemoDashboardScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DemoProvider>(context, listen: false).load();
    });
    // Rebuild every second so countdowns stay live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Classes'),
        actions: [
          IconButton(
            tooltip: 'Check-In History',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CheckInHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDemoScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Demo'),
      ),
      body: Consumer<DemoProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statsRow(provider),
                const SizedBox(height: 20),
                if (provider.suspiciousCheckIns > 0) ...[
                  _fraudBanner(provider.suspiciousCheckIns),
                  const SizedBox(height: 16),
                ],
                _sectionTitle('Active Demos', provider.activeDemos.length),
                const SizedBox(height: 8),
                if (provider.activeDemos.isEmpty)
                  _emptyHint('No active demos. Tap "New Demo" to add one.')
                else
                  ...provider.activeDemos.map((d) => _demoCard(d, provider)),
                const SizedBox(height: 20),
                _sectionTitle('Completed', provider.completedDemos.length),
                const SizedBox(height: 8),
                if (provider.completedDemos.isEmpty)
                  _emptyHint('No completed demos yet.')
                else
                  ...provider.completedDemos
                      .map((d) => _demoCard(d, provider)),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statsRow(DemoProvider provider) {
    return Row(
      children: [
        _statCard(
          'Active',
          provider.activeDemos.length.toString(),
          Icons.pending_actions,
          AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        _statCard(
          'Check-Ins',
          provider.totalCheckIns.toString(),
          Icons.check_circle,
          AppTheme.successColor,
        ),
        const SizedBox(width: 12),
        _statCard(
          'Flagged',
          provider.suspiciousCheckIns.toString(),
          Icons.warning_amber,
          AppTheme.errorColor,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fraudBanner(int count) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gpp_bad, color: AppTheme.errorColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count suspicious check-in(s) detected. '
              'Open history to review flags.',
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black45),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _demoCard(DemoClass demo, DemoProvider provider) {
    final df = DateFormat('EEE, dd MMM • hh:mm a');
    final isActive = demo.status == 'pending' || demo.status == 'checked_in';
    final countdown = _countdownText(demo.scheduledAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    demo.guardianName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _statusChip(demo.status),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.tag, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  demo.tuitionCode,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    demo.address,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  df.format(demo.scheduledAt),
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
            if (isActive && countdown != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer,
                        size: 14, color: AppTheme.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      countdown,
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (demo.checkIns.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.verified,
                      size: 14, color: AppTheme.successColor),
                  const SizedBox(width: 4),
                  Text(
                    '${demo.genuineVisitDays} genuine visit day(s) in 30 days'
                    ' • ${demo.checkIns.length} check-in(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (demo.hasGuardianLocation)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openMaps(demo),
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Navigate'),
                    ),
                  ),
                if (demo.hasGuardianLocation) const SizedBox(width: 8),
                if (isActive)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startCheckIn(demo),
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Check In'),
                    ),
                  ),
              ],
            ),
            if (demo.checkIns.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openVisitProof(demo),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  icon: const Icon(Icons.fact_check, size: 18),
                  label: const Text('Visit Proof (30 days)'),
                ),
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (demo.checkIns.isNotEmpty)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _confirmComplete(demo, provider),
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Mark Completed'),
                      ),
                    ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(demo, provider),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color c;
    String label;
    switch (status) {
      case 'checked_in':
        c = AppTheme.successColor;
        label = 'Checked In';
        break;
      case 'completed':
        c = AppTheme.primaryColor;
        label = 'Completed';
        break;
      case 'cancelled':
        c = Colors.grey;
        label = 'Cancelled';
        break;
      default:
        c = AppTheme.warningColor;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  String? _countdownText(DateTime scheduledAt) {
    final now = DateTime.now();
    final diff = scheduledAt.difference(now);
    if (diff.isNegative) {
      final late = now.difference(scheduledAt);
      if (late.inHours >= 24) return null;
      return 'Overdue by ${_fmtDuration(late)}';
    }
    return 'Starts in ${_fmtDuration(diff)}';
  }

  String _fmtDuration(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours % 24}h';
    }
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Future<void> _startCheckIn(DemoClass demo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckInScreen(demo: demo)),
    );
  }

  Future<void> _openVisitProof(DemoClass demo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VisitProofScreen(demoId: demo.id)),
    );
  }

  Future<void> _openMaps(DemoClass demo) async {
    final lat = demo.guardianLat;
    final lng = demo.guardianLng;
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
    } else {
      final q = Uri.encodeComponent(demo.address);
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  Future<void> _confirmComplete(
      DemoClass demo, DemoProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Completed?'),
        content: const Text(
          'This demo will move to the Completed section.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.completeDemo(demo.id);
    }
  }

  Future<void> _confirmDelete(DemoClass demo, DemoProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Demo?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.deleteDemo(demo.id);
    }
  }
}
