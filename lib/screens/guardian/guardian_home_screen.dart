import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../providers/guardian_provider.dart';
import '../auth/welcome_screen.dart';
import 'guardian_apply_screen.dart';
import 'guardian_review_screen.dart';

/// Guardian panel home. Shows the teacher(s) assigned to this guardian, pulled
/// from the live API (matched by the guardian's phone against the tuition's
/// guardian number on the backend). Also entry points to apply for a tutor
/// and to review the assigned teacher.
class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GuardianProvider>(context, listen: false).loadMyTeachers();
    });
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Do you want to exit and log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    if (!mounted) return;

    final guardian = Provider.of<GuardianProvider>(context, listen: false);
    await guardian.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GuardianApplyScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Apply for Tutor'),
      ),
      body: Consumer<GuardianProvider>(
        builder: (context, guardian, _) {
          return RefreshIndicator(
            onRefresh: guardian.loadMyTeachers,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _greeting(guardian),
                const SizedBox(height: 16),
                const Text(
                  'Your Assigned Teacher',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (guardian.teachersLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (guardian.teachers.isEmpty)
                  _emptyState(guardian)
                else
                  ...guardian.teachers.map(_teacherCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _greeting(GuardianProvider guardian) {
    final name = guardian.guardian?['name'] ?? 'Guardian';
    return Card(
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppTheme.primaryColor, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome,',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(GuardianProvider guardian) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              guardian.error ??
                  'No teacher is assigned to your number yet.\n'
                      'Once a tutor is appointed, they will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: guardian.loadMyTeachers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teacherCard(dynamic item) {
    final teacher = item['teacher'] as Map<String, dynamic>?;
    final tuition = item['tuition'] as Map<String, dynamic>?;
    final photo = ApiConfig.resolveImageUrl(teacher?['photo']);
    final name = teacher?['name'] ?? 'Teacher';
    final teacherId = teacher?['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.backgroundColor,
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (teacher?['code'] != null)
                        Text('Code: ${teacher!['code']}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      if (item['status'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _statusChip(item['status'].toString()),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (teacher?['phone'] != null)
              _row(Icons.phone, 'Phone', teacher!['phone'].toString()),
            if (teacher?['university'] != null)
              _row(Icons.school, 'University', teacher!['university'].toString()),
            if (teacher?['department'] != null)
              _row(Icons.menu_book, 'Department',
                  teacher!['department'].toString()),
            if (tuition?['subjects'] != null)
              _row(Icons.book, 'Subjects', tuition!['subjects'].toString()),
            if (tuition?['class'] != null)
              _row(Icons.grade, 'Class', tuition!['class'].toString()),
            if (tuition?['salary'] != null)
              _row(Icons.payments, 'Salary', '৳${tuition!['salary']}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: teacherId == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GuardianReviewScreen(
                                  teacherId: teacherId is int
                                      ? teacherId
                                      : int.tryParse('$teacherId') ?? 0,
                                  teacherName: name.toString(),
                                  assignmentId: item['assignment_id'] is int
                                      ? item['assignment_id']
                                      : int.tryParse(
                                          '${item['assignment_id']}'),
                                ),
                              ),
                            ),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Review'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    Color c = AppTheme.textSecondary;
    if (s.contains('active') || s.contains('confirm')) c = AppTheme.successColor;
    if (s.contains('pending')) c = AppTheme.warningColor;
    if (s.contains('cancel')) c = AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
