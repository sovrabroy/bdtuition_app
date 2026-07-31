import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/teacher_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  // Editable field controllers
  final _expectedClassController = TextEditingController();
  final _expectedSubjectController = TextEditingController();
  final _expectedMediumController = TextEditingController();
  final _dayPerWeekController = TextEditingController();
  final _expectedSalaryController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _collegeNameController = TextEditingController();
  final _universityNameController = TextEditingController();
  final _presentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeacherProvider>(context, listen: false).loadProfile();
    });
  }

  void _populateControllers(Map<String, dynamic> profile) {
    _expectedClassController.text = profile['expected_class'] ?? '';
    _expectedSubjectController.text = profile['expected_subject'] ?? '';
    _expectedMediumController.text = profile['expected_medium'] ?? '';
    _dayPerWeekController.text = '${profile['day_per_week'] ?? ''}';
    _expectedSalaryController.text = '${profile['expected_salary'] ?? ''}';
    _schoolNameController.text = profile['school_name'] ?? '';
    _collegeNameController.text = profile['college_name'] ?? '';
    _universityNameController.text = profile['university_name'] ?? '';
    _presentAddressController.text = profile['present_address'] ?? '';
    _permanentAddressController.text = profile['permanent_address'] ?? '';
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final provider = Provider.of<TeacherProvider>(context, listen: false);
    final data = {
      'expected_class': _expectedClassController.text.trim(),
      'expected_subject': _expectedSubjectController.text.trim(),
      'expected_medium': _expectedMediumController.text.trim(),
      'day_per_week': _dayPerWeekController.text.trim(),
      'expected_salary': _expectedSalaryController.text.trim(),
      'school_name': _schoolNameController.text.trim(),
      'college_name': _collegeNameController.text.trim(),
      'university_name': _universityNameController.text.trim(),
      'present_address': _presentAddressController.text.trim(),
      'permanent_address': _permanentAddressController.text.trim(),
    };

    final success = await provider.updateProfile(data);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (success) _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profile updated successfully!' : 'Failed to update profile',
        ),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  @override
  void dispose() {
    _expectedClassController.dispose();
    _expectedSubjectController.dispose();
    _expectedMediumController.dispose();
    _dayPerWeekController.dispose();
    _expectedSalaryController.dispose();
    _schoolNameController.dispose();
    _collegeNameController.dispose();
    _universityNameController.dispose();
    _presentAddressController.dispose();
    _permanentAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.profileData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = provider.profileData;
        if (profile == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load profile',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadProfile(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Builder(builder: (context) {
                        final photoUrl = ApiConfig.resolveImageUrl(
                            profile['personal_photo'] ??
                                profile['photo'] ??
                                profile['image'] ??
                                profile['avatar']);
                        return CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white24,
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? const Icon(Icons.person,
                                  size: 45, color: Colors.white)
                              : null,
                        );
                      }),
                      const SizedBox(height: 12),
                      Text(
                        profile['teacher_name'] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${profile['teacher_code'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(profile['status']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile['status'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Edit mode toggle
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      if (!_isEditing) {
                        _populateControllers(profile);
                      }
                      setState(() => _isEditing = !_isEditing);
                    },
                    icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 18),
                    label: Text(_isEditing ? 'Cancel' : 'Edit Profile'),
                  ),
                ),

                // Personal Information (read-only)
                _SectionCard(
                  title: 'Personal Information',
                  children: [
                    _InfoRow('Name', profile['teacher_name'] ?? 'N/A'),
                    _InfoRow('Phone', profile['phone_number'] ?? 'N/A'),
                    _InfoRow('Email', profile['email'] ?? 'N/A'),
                    _InfoRow('Gender', profile['gender'] ?? 'N/A'),
                    _InfoRow(
                        'Date of Birth', profile['date_of_birth'] ?? 'N/A'),
                    _InfoRow(
                        'National ID', profile['national_id'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 12),

                // Address (editable)
                _SectionCard(
                  title: 'Address',
                  children: _isEditing
                      ? [
                          _EditableField(
                            label: 'Present Address',
                            controller: _presentAddressController,
                          ),
                          _EditableField(
                            label: 'Permanent Address',
                            controller: _permanentAddressController,
                          ),
                        ]
                      : [
                          _InfoRow('Present Address',
                              profile['present_address'] ?? 'N/A'),
                          _InfoRow('Permanent Address',
                              profile['permanent_address'] ?? 'N/A'),
                        ],
                ),
                const SizedBox(height: 12),

                // Education (editable)
                _SectionCard(
                  title: 'Education',
                  children: _isEditing
                      ? [
                          _EditableField(
                            label: 'School Name',
                            controller: _schoolNameController,
                          ),
                          _EditableField(
                            label: 'College Name',
                            controller: _collegeNameController,
                          ),
                          _EditableField(
                            label: 'University Name',
                            controller: _universityNameController,
                          ),
                        ]
                      : [
                          _InfoRow('School',
                              profile['school_name'] ?? 'N/A'),
                          _InfoRow('College',
                              profile['college_name'] ?? 'N/A'),
                          _InfoRow('University',
                              profile['university_name'] ?? 'N/A'),
                        ],
                ),
                const SizedBox(height: 12),

                // Tuition Preferences (editable)
                _SectionCard(
                  title: 'Tuition Preferences',
                  children: _isEditing
                      ? [
                          _EditableField(
                            label: 'Expected Class',
                            controller: _expectedClassController,
                          ),
                          _EditableField(
                            label: 'Expected Subject',
                            controller: _expectedSubjectController,
                          ),
                          _EditableField(
                            label: 'Expected Medium',
                            controller: _expectedMediumController,
                          ),
                          _EditableField(
                            label: 'Days Per Week',
                            controller: _dayPerWeekController,
                            keyboardType: TextInputType.number,
                          ),
                          _EditableField(
                            label: 'Expected Salary',
                            controller: _expectedSalaryController,
                            keyboardType: TextInputType.number,
                            prefix: '৳',
                          ),
                        ]
                      : [
                          _InfoRow('Expected Class',
                              profile['expected_class'] ?? 'N/A'),
                          _InfoRow('Expected Subject',
                              profile['expected_subject'] ?? 'N/A'),
                          _InfoRow('Expected Medium',
                              profile['expected_medium'] ?? 'N/A'),
                          _InfoRow('Days Per Week',
                              '${profile['day_per_week'] ?? 'N/A'}'),
                          _InfoRow('Expected Salary',
                              '৳${profile['expected_salary'] ?? 'N/A'}'),
                        ],
                ),
                const SizedBox(height: 20),

                // Save button
                if (_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'approved':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'rejected':
      case 'banned':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

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

class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? prefix;

  const _EditableField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          isDense: true,
        ),
      ),
    );
  }
}
