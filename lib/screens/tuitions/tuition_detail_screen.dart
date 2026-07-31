import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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

                  // Details sections. Each row uses _pick() so it works no
                  // matter which key name the API sends, and empty values are
                  // hidden instead of showing "N/A".
                  _SectionCard(
                    title: 'Tuition Information',
                    children: [
                      _row('Class', _pick(tuition, ['class', 'student_class'])),
                      _row('Subject',
                          _pick(tuition, ['subject', 'subjects', 'subject_name', 'prefered_subjects', 'preferred_subjects'])),
                      _row('Medium', _pick(tuition, ['medium', 'version'])),
                      _row('Days Per Week', _pick(tuition,
                          ['day_per_week', 'days_per_week', 'day', 'days'])),
                      _row('Time', _pick(tuition, [
                        'time',
                        'preferred_time',
                        'prefered_time',
                        'tuition_time',
                        'tution_time',
                        'class_time'
                      ])),
                      _row('Duration',
                          _pick(tuition, ['duration', 'class_duration', 'prefered_duration', 'preferred_duration'])),
                      _row('Category',
                          _pick(tuition, ['category', 'tuition_category'])),
                      _row('Curriculum',
                          _pick(tuition, ['curriculum', 'syllabus'])),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _SectionCard(
                    title: 'Salary & Fees',
                    children: [
                      _row('Salary',
                          _money(_pick(tuition, ['salary', 'salary_amount']))),
                      _row(
                          'Salary Range',
                          _pick(tuition,
                              ['salary_range', 'salary_from_to'])),
                      _row('Media Fee', _pick(tuition, [
                        'media_fee',
                        'media_commission',
                        'media',
                        'commission',
                        'media_charge'
                      ])),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _SectionCard(
                    title: 'Location',
                    children: [
                      _row('City', _pick(tuition, ['city', 'district'])),
                      _row('Area', _pick(tuition, ['area', 'location'])),
                      _addressRow(
                        'Address',
                        _pick(tuition, [
                          'address',
                          'full_address',
                          'tuition_address'
                        ]),
                        _pick(tuition, [
                          'area',
                          'location',
                        ]),
                        _pick(tuition, ['city', 'district']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _SectionCard(
                    title: 'Requirements',
                    children: [
                      _row(
                          'Preferred Gender',
                          _pick(tuition,
                              ['prefered_gender', 'preferred_gender', 'gender'])),
                      _row(
                          'Number of Students',
                          _pick(tuition,
                              ['number_of_students', 'no_of_students', 'students'])),
                      _row('Other Requirements',
                          _pick(tuition, ['other_requirements', 'requirements', 'tutor_requirement', 'tutor_requirements'])),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Contact info (usually only present after the guardian is
                  // revealed / eligible). Shown only when the API returns it.
                  _ContactCard(tuition: tuition),

                  // Anything else the API sent that we didn't render above —
                  // shown automatically so no field is ever missed.
                  _AdditionalInfoCard(tuition: tuition),

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

                  // Apply / Already Applied button.
                  // Show "Apply" by default. Only hide it if the teacher has
                  // already applied, or if the backend EXPLICITLY says the
                  // teacher is not eligible (can_apply == false). When the flag
                  // is absent we still allow applying — the server does the
                  // final eligibility check when the application is submitted.
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
                  else if (tuition['can_apply'] == false)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _pick(tuition, [
                              'apply_reason',
                              'not_eligible_reason',
                              'eligibility_message',
                            ]).isNotEmpty
                            ? _pick(tuition, [
                                'apply_reason',
                                'not_eligible_reason',
                                'eligibility_message',
                              ])
                            : 'Not eligible to apply',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
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

  /// Returns the first non-empty value among [keys], or '' if none present.
  /// Lets us support several possible API field names for the same info.
  String _pick(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null') continue;
      return s;
    }
    return '';
  }

  /// Prefix a currency symbol when the value is a bare number.
  String _money(String value) {
    if (value.isEmpty) return '';
    final hasSymbol = value.contains('৳') ||
        value.toLowerCase().contains('tk') ||
        value.contains('%');
    return hasSymbol ? value : '৳$value';
  }

  /// A detail row that hides itself when the value is empty.
  Widget _row(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return _DetailRow(label, value);
  }

  /// A tappable address row that opens the location in Google Maps.
  /// Uses the address itself plus area/city to build a precise search query.
  Widget _addressRow(String label, String address, String area, String city) {
    if (address.trim().isEmpty) return const SizedBox.shrink();

    final query = [address, area, city]
        .where((p) => p.trim().isNotEmpty)
        .toSet()
        .join(', ');

    return InkWell(
      onTap: () => _openMaps(query),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 130,
              child: Text(
                'Address',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Row(
                    children: [
                      Icon(Icons.map, size: 14, color: AppTheme.primaryColor),
                      SizedBox(width: 4),
                      Text(
                        'Open in Google Maps',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Launches Google Maps with a search for the given location text.
  Future<void> _openMaps(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded');
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
    // Hide the whole card (title + divider) if every row rendered nothing.
    // Empty rows come back as SizedBox.shrink() (width/height == 0).
    final visible = children.where((w) => w is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

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
            ...visible,
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

/// Shows guardian/contact info with tap-to-call and WhatsApp buttons.
/// Only rendered when the API actually returns a contact number.
class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> tuition;

  const _ContactCard({required this.tuition});

  String _pick(List<String> keys) {
    for (final k in keys) {
      final v = tuition[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null') continue;
      return s;
    }
    return '';
  }

  Future<void> _launch(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final phone = _pick(
        ['contact', 'contact_number', 'phone', 'phone_number', 'mobile', 'whatsapp']);
    final instruction =
        _pick(['contact_instruction', 'apply_instruction', 'sms_instruction']);

    if (phone.isEmpty && instruction.isEmpty) {
      return const SizedBox.shrink();
    }

    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Divider(height: 20),
              if (instruction.isNotEmpty) ...[
                Text(
                  instruction,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (phone.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.phone,
                        size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _launch(Uri.parse('tel:$digits')),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launch(Uri.parse(
                            'https://wa.me/${digits.replaceAll('+', '')}')),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Automatically renders any remaining API fields we didn't explicitly place
/// in a section above. Guarantees no data from the backend is ever hidden.
class _AdditionalInfoCard extends StatelessWidget {
  final Map<String, dynamic> tuition;

  const _AdditionalInfoCard({required this.tuition});

  // Keys already shown elsewhere or that are internal/not useful to display.
  static const Set<String> _handled = {
    'id',
    'class', 'student_class',
    'subject', 'subjects', 'subject_name', 'prefered_subjects', 'preferred_subjects',
    'medium', 'version',
    'day_per_week', 'days_per_week', 'day', 'days',
    'time', 'preferred_time', 'prefered_time', 'tuition_time', 'tution_time', 'class_time',
    'duration', 'class_duration', 'prefered_duration', 'preferred_duration',
    'category', 'tuition_category',
    'curriculum', 'syllabus',
    'salary', 'salary_amount', 'salary_range', 'salary_from_to',
    'media_fee', 'media_commission', 'media', 'commission', 'media_charge',
    'city', 'district', 'area', 'location', 'address', 'full_address', 'tuition_address',
    'prefered_gender', 'preferred_gender', 'gender',
    'number_of_students', 'no_of_students', 'students',
    'other_requirements', 'requirements', 'tutor_requirement', 'tutor_requirements',
    'contact', 'contact_number', 'phone', 'phone_number', 'mobile', 'whatsapp',
    'contact_instruction', 'apply_instruction', 'sms_instruction',
    'tuition_code', 'start_date',
    // Guardian's private note about the student — must never be shown to teachers.
    'student_short_details', 'student_details', 'short_details',
    // Flags used by the UI logic, not for display.
    'has_applied', 'can_apply', 'total_applicants', 'status',
    'created_at', 'updated_at', 'deleted_at',
  };

  String _humanize(String key) {
    final cleaned = key.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    tuition.forEach((key, value) {
      if (_handled.contains(key)) return;
      if (value == null) return;
      // Skip nested objects/lists — only show simple scalar values.
      if (value is Map || value is List) return;
      final s = value.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return;
      rows.add(_DetailRow(_humanize(key), s));
    });

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _SectionCard(
        title: 'Additional Information',
        children: rows,
      ),
    );
  }
}
