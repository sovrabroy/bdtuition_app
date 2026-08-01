import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/bd_locations.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';

// ---- Teaching-preference option lists (used in registration & profile) ----
const List<String> kExpectedMediums = [
  'Bangla medium',
  'English Version /NC',
  'British Curriculum',
  'American Curriculum',
  'IB Curriculum',
  'Madrasa Curriculum',
];

const List<String> kExpectedSalaryRanges = [
  '2000-3000',
  '4000-5000',
  '6000-8000',
  '8000-10000',
  '12000-15000',
  '20000+',
];

const List<String> kExpectedClasses = [
  'Play', 'Nursery', 'KG',
  'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
  'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  'SSC', 'HSC', 'O Level', 'A Level',
  'Admission', 'Honours/University',
];

// Grouped so the teacher can pick subjects under the right category.
const Map<String, List<String>> kExpectedSubjectGroups = {
  'Common': ['General Math', 'English', 'Bangla', 'ICT'],
  'Science': ['Higher Math', 'Physics', 'Chemistry', 'Biology', 'Statistics'],
  'Commerce': ['Accounting', 'Finance', 'Marketing', 'Management', 'Economics'],
  'Arts': ['Geography', 'Logic', 'Psychology', 'Sociology', 'History', 'Islamic History', 'Civics'],
  'Special': ['Quran', 'Spoken English', 'IELTS', 'Drawing & Hand Writing', 'Dance', 'Music', 'Guitar'],
};

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final _picker = ImagePicker();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _fatherPhoneCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _motherPhoneCtrl = TextEditingController();
  final _localGuardianCtrl = TextEditingController();
  final _deptFriendCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _collegeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _sscGpaCtrl = TextEditingController();
  final _hscGpaCtrl = TextEditingController();

  String _gender = 'Male';
  String _medium = 'Bangla medium';
  String _academicYear = '1st year';
  String _sscGroup = 'Science';
  String _hscGroup = 'Science';
  String _city = 'Dhaka';
  String? _area;
  List<String> _expectedAreas = [];
  // Teaching preference (asked at registration, also editable in profile).
  String _expectedMedium = kExpectedMediums.first;
  String _dayPerWeek = '3';
  String _expectedSalary = kExpectedSalaryRanges.first;
  final List<String> _expectedClasses = [];
  final List<String> _expectedSubjects = [];

  // Image files
  File? _universityIdPhoto;
  File? _nidFront;
  File? _nidBack;
  File? _personalPhoto;
  File? _selfie;

  Future<void> _pickImage(String field) async {
    // Selfie must be a live front-camera capture (no gallery upload);
    // everything else is a normal gallery pick.
    final bool isSelfie = field == 'selfie';
    final picked = await _picker.pickImage(
      source: isSelfie ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        switch (field) {
          case 'university_id_photo': _universityIdPhoto = File(picked.path); break;
          case 'nid_front': _nidFront = File(picked.path); break;
          case 'nid_back': _nidBack = File(picked.path); break;
          case 'personal_photo': _personalPhoto = File(picked.path); break;
          case 'selfie': _selfie = File(picked.path); break;
        }
      });
    }
  }

  Future<void> _handleRegister() async {
    if (_personalPhoto == null || _universityIdPhoto == null || _nidFront == null || _nidBack == null || _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required photos'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    final formData = FormData.fromMap({
      'teacher_name': _nameCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      'whatsapp_number': _whatsappCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'facebook_link': _facebookCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'gender': _gender,
      'university_name': _universityCtrl.text.trim(),
      'department_name': _departmentCtrl.text.trim(),
      'school_name': _schoolCtrl.text.trim(),
      'college_name': _collegeCtrl.text.trim(),
      'academic_year': _academicYear,
      'ssc_group': _sscGroup,
      'ssc_gpa': _sscGpaCtrl.text.trim(),
      'hsc_group': _hscGroup,
      'hsc_gpa': _hscGpaCtrl.text.trim(),
      'medium': _medium,
      'city': _city,
      'area': _area ?? '',
      'expected_area': _expectedAreas,
      // Teaching preference collected at registration.
      'expected_class': _expectedClasses.join(', '),
      'expected_subject': _expectedSubjects.join(', '),
      'expected_medium': _expectedMedium,
      'day_per_week': _dayPerWeek,
      'expected_salary': _expectedSalary,
      'living_address': _addressCtrl.text.trim(),
      'father_name': _fatherNameCtrl.text.trim(),
      'father_brother_phone': _fatherPhoneCtrl.text.trim(),
      'mother_name': _motherNameCtrl.text.trim(),
      'mother_sister_phone': _motherPhoneCtrl.text.trim(),
      'local_guardian_phone': _localGuardianCtrl.text.trim(),
      'departmental_friend_phone': _deptFriendCtrl.text.trim(),
      'university_id_photo': await MultipartFile.fromFile(_universityIdPhoto!.path),
      'nid_front': await MultipartFile.fromFile(_nidFront!.path),
      'nid_back': await MultipartFile.fromFile(_nidBack!.path),
      'personal_photo': await MultipartFile.fromFile(_personalPhoto!.path),
      'selfie': await MultipartFile.fromFile(_selfie!.path),
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.register({'formData': formData});

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OTPScreen(phoneNumber: _phoneCtrl.text.trim())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration failed'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  void _toggleExpectedArea(String area) {
    setState(() {
      if (_expectedAreas.contains(area)) {
        _expectedAreas.remove(area);
      } else {
        _expectedAreas.add(area);
      }
    });
  }

  void _toggleFromList(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Widget _buildImagePicker(String label, File? file, String field) {
    final bool isSelfie = field == 'selfie';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(field),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(file, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isSelfie ? Icons.camera_front : Icons.camera_alt,
                          size: 36, color: Colors.grey),
                      const SizedBox(height: 4),
                      Text(isSelfie ? 'Tap to open front camera' : 'Tap to upload',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register as Teacher')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep++);
          } else {
            _handleRegister();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 3 ? 'Register' : 'Next'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          // Step 1: Personal Info
          Step(
            title: const Text('Personal Info'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                const SizedBox(height: 12),
                TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number *')),
                const SizedBox(height: 12),
                TextFormField(controller: _whatsappCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp Number *')),
                const SizedBox(height: 12),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email *')),
                const SizedBox(height: 12),
                TextFormField(controller: _facebookCtrl, decoration: const InputDecoration(labelText: 'Facebook Link *')),
                const SizedBox(height: 12),
                TextFormField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password *')),
                const SizedBox(height: 12),
                TextFormField(controller: _confirmPasswordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Gender *'),
                  items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _gender = v!),
                ),
              ],
            ),
          ),

          // Step 2: Education
          Step(
            title: const Text('Education'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                TextFormField(controller: _schoolCtrl, decoration: const InputDecoration(labelText: 'School Name *')),
                const SizedBox(height: 12),
                TextFormField(controller: _collegeCtrl, decoration: const InputDecoration(labelText: 'College Name *')),
                const SizedBox(height: 12),
                TextFormField(controller: _universityCtrl, decoration: const InputDecoration(labelText: 'University Name *')),
                const SizedBox(height: 12),
                TextFormField(controller: _departmentCtrl, decoration: const InputDecoration(labelText: 'Department *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _academicYear,
                  decoration: const InputDecoration(labelText: 'Academic Year *'),
                  items: ['1st year', '2nd year', '3rd year', '4th year', '5th year/Masters', 'Completed']
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (v) => setState(() => _academicYear = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _medium,
                  decoration: const InputDecoration(labelText: 'Medium *'),
                  items: ['Bangla medium', 'English version', 'English medium', 'Madrasa']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _medium = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _sscGroup,
                  decoration: const InputDecoration(labelText: 'SSC/O Level Group *'),
                  items: kAcademicGroups
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _sscGroup = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sscGpaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'SSC/O Level GPA *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _hscGroup,
                  decoration: const InputDecoration(labelText: 'HSC/A Level Group *'),
                  items: kAcademicGroups
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _hscGroup = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hscGpaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'HSC/A Level GPA *'),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Teaching Preference',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 12),
                // Expected Class — multiple select.
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Expected Class * (select one or more)',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: kExpectedClasses.map((c) {
                    return FilterChip(
                      label: Text(c),
                      selected: _expectedClasses.contains(c),
                      onSelected: (_) => _toggleFromList(_expectedClasses, c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Expected Subject — multiple select, grouped by category.
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Expected Subject * (select one or more)',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                ...kExpectedSubjectGroups.entries.map((group) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text('${group.key} subject',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: group.value.map((s) {
                          return FilterChip(
                            label: Text(s),
                            selected: _expectedSubjects.contains(s),
                            onSelected: (_) => _toggleFromList(_expectedSubjects, s),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _expectedMedium,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Expected Medium *'),
                  items: kExpectedMediums
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _expectedMedium = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _dayPerWeek,
                  decoration: const InputDecoration(labelText: 'Day per Week *'),
                  items: ['1', '2', '3', '4', '5', '6', '7']
                      .map((d) => DropdownMenuItem(value: d, child: Text('$d day/week')))
                      .toList(),
                  onChanged: (v) => setState(() => _dayPerWeek = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _expectedSalary,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Expected Salary * (৳ per month)'),
                  items: kExpectedSalaryRanges
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _expectedSalary = v!),
                ),
              ],
            ),
          ),

          // Step 3: Location & Family
          Step(
            title: const Text('Location & Family'),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _city,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'City / District *'),
                  items: kBdDistricts
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _city = v!;
                    // Reset area selections when the city changes.
                    _area = null;
                    _expectedAreas = [];
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _area,
                  isExpanded: true,
                  hint: const Text('Select area'),
                  decoration: const InputDecoration(labelText: 'Area *'),
                  items: kBdAreasFor(_city)
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() => _area = v),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Living Address *')),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Expected Areas (select one or more)',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: kBdAreasFor(_city).map((a) {
                    final selected = _expectedAreas.contains(a);
                    return FilterChip(
                      label: Text(a),
                      selected: selected,
                      onSelected: (_) => _toggleExpectedArea(a),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _fatherNameCtrl, decoration: const InputDecoration(labelText: 'Father Name *')),
                const SizedBox(height: 12),
                TextFormField(controller: _fatherPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Father Phone *')),
                const SizedBox(height: 12),
                TextFormField(controller: _motherNameCtrl, decoration: const InputDecoration(labelText: 'Mother Name *')),
                const SizedBox(height: 12),
                TextFormField(controller: _motherPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mother Phone *')),
                const SizedBox(height: 12),
                TextFormField(controller: _localGuardianCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Local Guardian Phone *')),
                const SizedBox(height: 12),
                TextFormField(controller: _deptFriendCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Departmental Friend Phone *')),
              ],
            ),
          ),

          // Step 4: Documents
          Step(
            title: const Text('Documents'),
            isActive: _currentStep >= 3,
            content: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Column(
                  children: [
                    _buildImagePicker('Personal Photo *', _personalPhoto, 'personal_photo'),
                    _buildImagePicker('University ID *', _universityIdPhoto, 'university_id_photo'),
                    _buildImagePicker('NID Front *', _nidFront, 'nid_front'),
                    _buildImagePicker('NID Back *', _nidBack, 'nid_back'),
                    _buildImagePicker('Selfie *', _selfie, 'selfie'),
                    if (auth.isLoading) const Center(child: CircularProgressIndicator()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _whatsappCtrl.dispose();
    _emailCtrl.dispose(); _facebookCtrl.dispose(); _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose(); _fatherNameCtrl.dispose(); _fatherPhoneCtrl.dispose();
    _motherNameCtrl.dispose(); _motherPhoneCtrl.dispose(); _localGuardianCtrl.dispose();
    _deptFriendCtrl.dispose(); _universityCtrl.dispose(); _departmentCtrl.dispose();
    _schoolCtrl.dispose(); _collegeCtrl.dispose();
    _addressCtrl.dispose(); _sscGpaCtrl.dispose(); _hscGpaCtrl.dispose();
    super.dispose();
  }
}
