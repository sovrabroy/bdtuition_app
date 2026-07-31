import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/demo_class.dart';
import '../../providers/demo_provider.dart';

/// Shows the 30-day "visit proof" for a single tuition/guardian.
///
/// This is the anti-fraud evidence: how many separate days the teacher REALLY
/// went to this address (verified GPS inside the guardian's geofence, no
/// mock/root/emulator flags). If the teacher later lies that they don't teach
/// this tuition — to dodge the media fee — this report proves otherwise.
class VisitProofScreen extends StatelessWidget {
  final String demoId;
  const VisitProofScreen({super.key, required this.demoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit Proof (30 days)')),
      body: Consumer<DemoProvider>(
        builder: (context, provider, _) {
          DemoClass? demo;
          for (final d in provider.demos) {
            if (d.id == demoId) {
              demo = d;
              break;
            }
          }
          if (demo == null) {
            return const Center(child: Text('This demo no longer exists.'));
          }
          return _body(context, demo);
        },
      ),
    );
  }

  Widget _body(BuildContext context, DemoClass demo) {
    final visits = demo.genuineVisits;
    final visitDays = demo.genuineVisitDays;
    final df = DateFormat('dd MMM yyyy');
    final dfTime = DateFormat('dd MMM yyyy • hh:mm a');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Who / where
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demo.guardianName,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _line(Icons.tag, demo.tuitionCode),
                const SizedBox(height: 2),
                _line(Icons.place, demo.address),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      demo.hasGuardianLocation
                          ? Icons.gps_fixed
                          : Icons.gps_off,
                      size: 15,
                      color: demo.hasGuardianLocation
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        demo.hasGuardianLocation
                            ? 'Home location locked — visits verified within '
                                '${DemoClass.geofenceRadiusMeters.toStringAsFixed(0)} m.'
                            : 'No home location pinned — visits verified by device integrity only. '
                                'Pin the location on first visit for stronger proof.',
                        style: TextStyle(
                          fontSize: 12,
                          color: demo.hasGuardianLocation
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Headline proof number
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '$visitDays',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'day(s) genuinely visited in the last 30 days',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (demo.firstGenuineVisit != null) ...[
                const SizedBox(height: 8),
                Text(
                  'From ${df.format(demo.firstGenuineVisit!)} '
                  'to ${df.format(demo.lastGenuineVisit!)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Verdict line
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (visitDays > 0 ? AppTheme.successColor : Colors.grey)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                visitDays > 0 ? Icons.verified : Icons.info_outline,
                color: visitDays > 0 ? AppTheme.successColor : Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  visitDays > 0
                      ? 'Proof: this teacher was physically at this address on '
                          '$visitDays separate day(s). This cannot be a "no tuition" case.'
                      : 'No genuine visits recorded yet in the last 30 days.',
                  style: TextStyle(
                    color:
                        visitDays > 0 ? AppTheme.successColor : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Visit Log',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            TextButton.icon(
              onPressed: () => _copyReport(context, demo),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Report'),
            ),
          ],
        ),
        const SizedBox(height: 4),

        if (visits.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No verified visits inside the address geofence yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45),
            ),
          )
        else
          ...visits.map((c) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1A4CAF50),
                  child: Icon(Icons.check, color: AppTheme.successColor),
                ),
                title: Text(dfTime.format(c.time)),
                subtitle: Text(
                  c.distanceFromGuardian != null
                      ? '${c.distanceFromGuardian!.toStringAsFixed(0)} m from home • '
                          '±${c.accuracy.toStringAsFixed(0)} m GPS'
                      : '±${c.accuracy.toStringAsFixed(0)} m GPS',
                ),
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _line(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.black45),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ),
      ],
    );
  }

  /// Builds a plain-text report and copies it to the clipboard so it can be
  /// pasted into WhatsApp / a message when confronting the teacher.
  Future<void> _copyReport(BuildContext context, DemoClass demo) async {
    final df = DateFormat('dd MMM yyyy, hh:mm a');
    final b = StringBuffer()
      ..writeln('VISIT PROOF (last 30 days)')
      ..writeln('Tuition: ${demo.tuitionCode}')
      ..writeln('Guardian: ${demo.guardianName}')
      ..writeln('Address: ${demo.address}')
      ..writeln('Genuine visit days: ${demo.genuineVisitDays}')
      ..writeln('');
    for (final c in demo.genuineVisits) {
      final dist = c.distanceFromGuardian != null
          ? ' (${c.distanceFromGuardian!.toStringAsFixed(0)} m from home)'
          : '';
      b.writeln('• ${df.format(c.time)}$dist');
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proof report copied to clipboard.')),
      );
    }
  }
}
