import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../config/bd_locations.dart';
import '../../providers/teacher_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  // Hardcoded option lists for the Tuition Preferences dropdowns.
  static const List<String> kClassOptions = [
    'Zero to Class 2',
    'Class 3 to Class 5',
    'Class 6 to Class 8',
    'SSC / O Level (Class 9 & 10)',
    'HSC / A Level (Class 11 & 12)',
    'University Admission Test',
    'Honours Level Student',
  ];

  static const Map<String, List<String>> kSubjectGroups = {
    'Common': ['General Math', 'English', 'Bangla', 'ICT'],
    'Science': ['Higher Math', 'Physics', 'Chemistry', 'Biology', 'Statistics'],
    'Commerce': [
      'Accounting',
      'Finance',
      'Marketing',
      'Management',
      'Economics',
      'Statistics',
    ],
    'Arts': [
      'Economics',
      'Geography',
      'Logic',
      'Psychology',
      'Sociology',
      'History',
      'Islamic History',
    ],
    'Special': [
      'Quran',
      'Spoken English',
      'IELTS',
      'Drawing & Hand Writing',
      'Dance',
      'Music',
      'Guitar',
    ],
  };

  static const List<String> kMediumOptions = [
    'Bangla Medium',
    'English Version / NC',
    'British Curriculum',
    'American Curriculum',
    'IB Curriculum',
    'Madrasa Curriculum',
  ];

  static const List<String> kDaysOptions = [
    '1 day',
    '2 days',
    '3 days',
    '4 days',
    '5 days',
    '6 days',
    '7 days',
  ];

  static const List<String> kSalaryOptions = [
    '2000 - 3000',
    '4000 - 5000',
    '6000 - 8000',
    '8000 - 10000',
    '12000 - 15000',
    '20000',
  ];

  // Academic year options (same set used on the registration screen).
  static const List<String> kAcademicYearOptions = [
    '1st year',
    '2nd year',
    '3rd year',
    '4th year',
    '5th year/Masters',
    'Completed',
  ];

  // Selected values for the Tuition Preferences dropdowns.
  String? _expectedClass;
  final List<String> _expectedSubjects = [];
  String? _expectedMedium;
  String? _maxDaysPerWeek;
  String? _minSalary;

  // Selected academic year for the Education section.
  String? _academicYear;

  // SSC / HSC group selections (groups are hardcoded; GPA is typed manually).
  String? _sscGroup;
  String? _hscGroup;

  // Editable field controllers
  final _departmentController = TextEditingController();
  final _sscGpaController = TextEditingController();
  final _hscGpaController = TextEditingController();
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
    // Seed dropdowns from saved values. Only accept a value that is one of the
    // known options (so old free-text data doesn't break the dropdown).
    _expectedClass = _matchOption(profile['expected_class'], kClassOptions);
    _expectedMedium = _matchOption(profile['expected_medium'], kMediumOptions);
    _maxDaysPerWeek = _matchOption(
        profile['day_per_week']?.toString(), kDaysOptions);
    _minSalary =
        _matchOption(profile['expected_salary']?.toString(), kSalaryOptions);

    final allSubjects =
        kSubjectGroups.values.expand((s) => s).toSet().toList();
    _expectedSubjects
      ..clear()
      ..addAll(
        (profile['expected_subject']?.toString() ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => allSubjects.contains(s)),
      );

    _departmentController.text =
        profile['department_name'] ?? profile['department'] ?? '';
    _academicYear = _matchOption(
        profile['academic_year']?.toString(), kAcademicYearOptions);

    _sscGroup = _matchOption(profile['ssc_group']?.toString(), kAcademicGroups);
    _hscGroup = _matchOption(profile['hsc_group']?.toString(), kAcademicGroups);
    _sscGpaController.text = profile['ssc_gpa']?.toString() ?? '';
    _hscGpaController.text = profile['hsc_gpa']?.toString() ?? '';

    _schoolNameController.text = profile['school_name'] ?? '';
    _collegeNameController.text = profile['college_name'] ?? '';
    _universityNameController.text = profile['university_name'] ?? '';
    _presentAddressController.text = profile['present_address'] ?? '';
    _permanentAddressController.text = profile['permanent_address'] ?? '';
  }

  /// Returns [value] only if it exactly matches one of [options], else null.
  String? _matchOption(String? value, List<String> options) {
    if (value == null) return null;
    final v = value.trim();
    return options.contains(v) ? v : null;
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final provider = Provider.of<TeacherProvider>(context, listen: false);
    final data = {
      'expected_class': _expectedClass ?? '',
      'expected_subject': _expectedSubjects.join(', '),
      'expected_medium': _expectedMedium ?? '',
      'day_per_week': _maxDaysPerWeek ?? '',
      'expected_salary': _minSalary ?? '',
      'department_name': _departmentController.text.trim(),
      'academic_year': _academicYear ?? '',
      'ssc_group': _sscGroup ?? '',
      'ssc_gpa': _sscGpaController.text.trim(),
      'hsc_group': _hscGroup ?? '',
      'hsc_gpa': _hscGpaController.text.trim(),
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
    _departmentController.dispose();
    _sscGpaController.dispose();
    _hscGpaController.dispose();
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
                          _EditableField(
                            label: 'Department',
                            controller: _departmentController,
                          ),
                          _DropdownField(
                            label: 'Academic Year',
                            value: _academicYear,
                            options: kAcademicYearOptions,
                            onChanged: (v) =>
                                setState(() => _academicYear = v),
                          ),
                          _DropdownField(
                            label: 'SSC/O Level Group',
                            value: _sscGroup,
                            options: kAcademicGroups,
                            onChanged: (v) => setState(() => _sscGroup = v),
                          ),
                          _EditableField(
                            label: 'SSC/O Level GPA',
                            controller: _sscGpaController,
                          ),
                          _DropdownField(
                            label: 'HSC/A Level Group',
                            value: _hscGroup,
                            options: kAcademicGroups,
                            onChanged: (v) => setState(() => _hscGroup = v),
                          ),
                          _EditableField(
                            label: 'HSC/A Level GPA',
                            controller: _hscGpaController,
                          ),
                        ]
                      : [
                          _InfoRow('School',
                              profile['school_name'] ?? 'N/A'),
                          _InfoRow('College',
                              profile['college_name'] ?? 'N/A'),
                          _InfoRow('University',
                              profile['university_name'] ?? 'N/A'),
                          _InfoRow(
                              'Department',
                              profile['department_name'] ??
                                  profile['department'] ??
                                  'N/A'),
                          _InfoRow('Academic Year',
                              profile['academic_year'] ?? 'N/A'),
                          _InfoRow('SSC/O Level Group',
                              profile['ssc_group'] ?? 'N/A'),
                          _InfoRow('SSC/O Level GPA',
                              profile['ssc_gpa']?.toString() ?? 'N/A'),
                          _InfoRow('HSC/A Level Group',
                              profile['hsc_group'] ?? 'N/A'),
                          _InfoRow('HSC/A Level GPA',
                              profile['hsc_gpa']?.toString() ?? 'N/A'),
                        ],
                ),
                const SizedBox(height: 12),

                // Tuition Preferences (editable)
                _SectionCard(
                  title: 'Tuition Preferences',
                  children: _isEditing
                      ? [
                          _DropdownField(
                            label: 'Expected Class',
                            value: _expectedClass,
                            options: kClassOptions,
                            onChanged: (v) =>
                                setState(() => _expectedClass = v),
                          ),
                          _SubjectPicker(
                            selected: _expectedSubjects,
                            groups: kSubjectGroups,
                            onChanged: () => setState(() {}),
                          ),
                          _DropdownField(
                            label: 'Expected Medium',
                            value: _expectedMedium,
                            options: kMediumOptions,
                            onChanged: (v) =>
                                setState(() => _expectedMedium = v),
                          ),
                          _DropdownField(
                            label: 'Maximum Days Per Week',
                            value: _maxDaysPerWeek,
                            options: kDaysOptions,
                            onChanged: (v) =>
                                setState(() => _maxDaysPerWeek = v),
                          ),
                          _DropdownField(
                            label: 'Minimum Salary',
                            value: _minSalary,
                            options: kSalaryOptions,
                            onChanged: (v) => setState(() => _minSalary = v),
                          ),
                        ]
                      : [
                          _InfoRow('Expected Class',
                              profile['expected_class'] ?? 'N/A'),
                          _InfoRow('Expected Subject',
                              profile['expected_subject'] ?? 'N/A'),
                          _InfoRow('Expected Medium',
                              profile['expected_medium'] ?? 'N/A'),
                          _InfoRow('Max Days Per Week',
                              '${profile['day_per_week'] ?? 'N/A'}'),
                          _InfoRow('Minimum Salary',
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

/// A single-choice dropdown backed by a fixed list of options.
class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// A grouped multi-select for subjects. A tutor can pick several subjects
/// across the Common / Science / Commerce / Arts / Special groups.
class _SubjectPicker extends StatelessWidget {
  final List<String> selected;
  final Map<String, List<String>> groups;
  final VoidCallback onChanged;

  const _SubjectPicker({
    required this.selected,
    required this.groups,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expected Subject',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: entry.value.map((subject) {
                final isSelected = selected.contains(subject);
                return FilterChip(
                  label: Text(subject, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (val) {
                    if (val) {
                      if (!selected.contains(subject)) selected.add(subject);
                    } else {
                      selected.remove(subject);
                    }
                    onChanged();
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
