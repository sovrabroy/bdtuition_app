import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/tuition_provider.dart';

class TuitionDetailScreen extends StatefulWidget {
  final int tuitionId;

  const TuitionDetailScreen({super.key, required this.tuitionId});

  @override
  State<TuitionDetailScreen> createState() => _TuitionDetailScreenState();
}

class _TuitionDetailScreenState extends State<TuitionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TuitionProvider>(context, listen: false)
          .loadTuitionDetails(widget.tuitionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuition Details'),
      ),
      body: Consumer<TuitionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedTuition == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final tuition = provider.selectedTuition;
          if (tuition == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppTheme.errorColor),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load tuition details',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadTuitionDetails(widget.tuitionId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadTuitionDetails(widget.tuitionId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tuition code header
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
                          tuition['tuition_code'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${tuition['area'] ?? ''}, ${tuition['city'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '৳${tuition['salary'] ?? '0'}/month',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details sections
                  _SectionCard(
                    title: 'Tuition Information',
                    children: [
                      _DetailRow('Class', tuition['class'] ?? 'N/A'),
                      _DetailRow('Subject', tuition['subject'] ?? 'N/A'),
                      _DetailRow('Medium', tuition['medium'] ?? 'N/A'),
                      _DetailRow(
                          'Days Per Week', '${tuition['day_per_week'] ?? 'N/A'}'),
                      _DetailRow('Category', tuition['category'] ?? 'N/A'),
                      _DetailRow('Curriculum', tuition['curriculum'] ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _SectionCard(
                    title: 'Location',
                    children: [
                      _DetailRow('City', tuition['city'] ?? 'N/A'),
                      _DetailRow('Area', tuition['area'] ?? 'N/A'),
                      if (tuition['address'] != null)
                        _DetailRow('Address', tuition['address']),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _SectionCard(
                    title: 'Requirements',
                    children: [
                      _DetailRow('Preferred Gender',
                          tuition['prefered_gender'] ?? 'N/A'),
                      _DetailRow('Number of Students',
                          '${tuition['number_of_students'] ?? 'N/A'}'),
                      if (tuition['other_requirements'] != null &&
                          tuition['other_requirements'].toString().isNotEmpty)
                        _DetailRow(
                            'Other Requirements', tuition['other_requirements']),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _SectionCard(
                    title: 'Schedule',
                    children: [
                      _DetailRow(
                          'Days Per Week', '${tuition['day_per_week'] ?? 'N/A'}'),
                      if (tuition['preferred_time'] != null)
                        _DetailRow('Preferred Time', tuition['preferred_time']),
                      if (tuition['start_date'] != null)
                        _DetailRow('Start Date', tuition['start_date']),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Applicant count
                  if (tuition['total_applicants'] != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.warningColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people,
                              color: AppTheme.warningColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${tuition['total_applicants']} teachers already applied',
                            style: const TextStyle(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Apply / Already Applied button
                  if (tuition['has_applied'] == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.warningColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Already Applied',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (tuition['can_apply'] == true)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showApplyDialog(tuition['id']),
                        icon: const Icon(Icons.send),
                        label: const Text('Apply for this Tuition'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Not eligible to apply',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showApplyDialog(int tuitionId) {
    final referenceController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apply for Tuition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide your authority reference (if any):',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Authority Reference',
                hintText: 'e.g., Referred by Mr. X',
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider =
                  Provider.of<TuitionProvider>(context, listen: false);
              final result = await provider.applyForTuition(
                tuitionId,
                referenceController.text.trim(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['message'] ??
                        (result['success'] == true
                            ? 'Applied successfully!'
                            : 'Failed to apply'),
                  ),
                  backgroundColor: result['success'] == true
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              );
              if (result['success'] == true) {
                provider.loadTuitionDetails(tuitionId);
              }
            },
            child: const Text('Submit Application'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
