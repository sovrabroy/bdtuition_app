import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/check_in.dart';
import '../../models/demo_class.dart';
import '../../providers/demo_provider.dart';

/// Attendance log / check-in history across all demos, with fraud flags.
class CheckInHistoryScreen extends StatelessWidget {
  const CheckInHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-In History')),
      body: Consumer<DemoProvider>(
        builder: (context, provider, _) {
          // Flatten every check-in across all demos (newest first).
          final entries = <MapEntry<DemoClass, CheckIn>>[];
          for (final d in provider.demos) {
            for (final c in d.checkIns) {
              entries.add(MapEntry(d, c));
            }
          }
          entries.sort((a, b) => b.value.time.compareTo(a.value.time));

          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No check-ins recorded yet.\n'
                  'Check-ins appear here with GPS & fraud details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            );
          }

          final flagged =
              entries.where((e) => e.value.isSuspicious).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryBar(entries.length, flagged),
              const SizedBox(height: 16),
              ...entries.map((e) => _historyCard(e.key, e.value)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryBar(int total, int flagged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
                'Total', total.toString(), AppTheme.primaryColor),
          ),
          Container(width: 1, height: 34, color: Colors.black12),
          Expanded(
            child: _summaryItem('Genuine', (total - flagged).toString(),
                AppTheme.successColor),
          ),
          Container(width: 1, height: 34, color: Colors.black12),
          Expanded(
            child:
                _summaryItem('Flagged', flagged.toString(), AppTheme.errorColor),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _historyCard(DemoClass demo, CheckIn c) {
    final df = DateFormat('dd MMM yyyy • hh:mm a');
    final suspicious = c.isSuspicious;
    final borderColor =
        suspicious ? AppTheme.errorColor : AppTheme.successColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  suspicious ? Icons.gpp_bad : Icons.verified_user,
                  color: borderColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    demo.guardianName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text(
                  suspicious ? 'FLAGGED' : 'GENUINE',
                  style: TextStyle(
                    color: borderColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _row(Icons.schedule, df.format(c.time)),
            _row(Icons.tag, demo.tuitionCode),
            _row(Icons.my_location,
                '${c.latitude.toStringAsFixed(6)}, ${c.longitude.toStringAsFixed(6)}'),
            _row(Icons.gps_fixed, 'Accuracy ±${c.accuracy.toStringAsFixed(1)} m'),
            if (c.distanceFromGuardian != null)
              _row(
                Icons.straighten,
                c.distanceFromGuardian! < 1000
                    ? '${c.distanceFromGuardian!.toStringAsFixed(0)} m from guardian'
                    : '${(c.distanceFromGuardian! / 1000).toStringAsFixed(2)} km from guardian',
              ),
            if (c.selfiePath != null &&
                File(c.selfiePath!).existsSync()) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(c.selfiePath!),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (suspicious) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _fraudFlags(c)
                      .map((f) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber,
                                    size: 14, color: AppTheme.errorColor),
                                const SizedBox(width: 6),
                                Text(
                                  f,
                                  style: const TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _fraudFlags(CheckIn c) {
    final f = <String>[];
    if (c.isMockLocation) f.add('Mock / Fake GPS detected');
    if (c.isRooted) f.add('Rooted device');
    if (c.isDeveloperMode) f.add('Developer mode enabled');
    if (!c.isRealDevice) f.add('Emulator / not a real device');
    return f;
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.black45),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
