import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/teacher_provider.dart';

class GuardianListScreen extends StatefulWidget {
  const GuardianListScreen({super.key});

  @override
  State<GuardianListScreen> createState() => _GuardianListScreenState();
}

class _GuardianListScreenState extends State<GuardianListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TeacherProvider>(context, listen: false);
      provider.loadGuardians();
      // Active Tuitions count comes from the dashboard payload — moved here
      // from the dashboard screen.
      if (provider.dashboardData == null) {
        provider.loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Active Tuitions summary — moved here from the dashboard.
        Consumer<TeacherProvider>(
          builder: (context, provider, _) {
            final active = provider.dashboardData?['active_assignments'] ?? 0;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Active Tuitions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(child: _buildGuardianList()),
      ],
    );
  }

  Widget _buildGuardianList() {
    return Consumer<TeacherProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.guardians.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.guardians.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 12),
                Text(
                  provider.error!,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadGuardians(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.guardians.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text(
                  'No assigned guardians yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Apply for tuitions to get assigned',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadGuardians(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.guardians.length,
            itemBuilder: (context, index) {
              final guardian = provider.guardians[index];
              return _GuardianCard(
                guardian: guardian,
                onTap: () => _showGuardianDetails(guardian),
                onCall: () => _callGuardian(guardian),
              );
            },
          ),
        );
      },
    );
  }

  void _showGuardianDetails(Map<String, dynamic> guardian) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final provider = Provider.of<TeacherProvider>(context, listen: false);
    final details =
        await provider.getGuardianDetails(guardian['assignment_id'] ?? guardian['id']);

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load guardian details'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Guardian Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Tuition info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _DetailItem('Tuition Code',
                            details['tuition_code'] ?? 'N/A'),
                        _DetailItem(
                            'Status', details['status'] ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Guardian info. The phone number is intentionally NOT
                  // shown — the teacher can only reach the guardian through the
                  // masked "Call Guardian" button, which routes via Issabel so
                  // the real number is never exposed.
                  _DetailItem('Guardian Name',
                      details['guardian_name'] ?? 'N/A'),
                  _DetailItem('Address',
                      details['address'] ?? 'N/A'),
                  _DetailItem('Area',
                      '${details['area'] ?? ''}, ${details['city'] ?? ''}'),
                  const Divider(height: 24),

                  // Tuition details
                  _DetailItem('Class', details['class'] ?? 'N/A'),
                  _DetailItem('Subject', details['subject'] ?? 'N/A'),
                  _DetailItem('Medium', details['medium'] ?? 'N/A'),
                  _DetailItem(
                      'Salary', '৳${details['salary'] ?? '0'}/month'),
                  _DetailItem('Days/Week',
                      '${details['day_per_week'] ?? 'N/A'}'),
                  const SizedBox(height: 16),

                  // Call button — masked call via Issabel.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _callGuardian(guardian);
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call Guardian'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Places a masked call to the guardian. The guardian's number is never
  /// shown to the teacher — the backend originates the call through Issabel:
  /// the teacher's own phone rings first, then gets bridged to the guardian.
  void _callGuardian(Map<String, dynamic> guardian) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.call, color: AppTheme.successColor),
            SizedBox(width: 8),
            Text('Call Guardian'),
          ],
        ),
        content: const Text(
          'We will connect you to the guardian. Your own phone will ring in a '
          'few seconds — pick it up and you will be connected. The guardian\'s '
          'number stays private.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Call'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final provider = Provider.of<TeacherProvider>(context, listen: false);
    final result = await provider
        .callGuardian(guardian['assignment_id'] ?? guardian['id']);

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    final success = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (result['message']?.toString() ??
                  'Connecting… your phone will ring shortly.')
              : (result['message']?.toString() ??
                  'Could not place the call. Please try again.'),
        ),
        backgroundColor:
            success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  final Map<String, dynamic> guardian;
  final VoidCallback onTap;
  final VoidCallback onCall;

  const _GuardianCard({
    required this.guardian,
    required this.onTap,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      guardian['tuition_code'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(guardian['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      guardian['status'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(guardian['status']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Location
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${guardian['area'] ?? ''}, ${guardian['city'] ?? ''}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Salary and details
              Row(
                children: [
                  const Icon(Icons.attach_money,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '৳${guardian['salary'] ?? '0'}/month',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (guardian['class'] != null)
                    Text(
                      'Class: ${guardian['class']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call Guardian'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'confirmed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'cancelled':
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
