import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../services/nearby_tuition_notifier.dart';
import '../auth/login_screen.dart';
import 'dashboard_screen.dart';
import '../tuitions/tuition_list_screen.dart';
import '../tuitions/tuition_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../guardians/guardian_list_screen.dart';
import '../payments/payment_screen.dart';
import '../demo/demo_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _goToTab(int index) {
    if (index >= 0 && index < 6) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeacherProvider>(context, listen: false).loadDashboard();
      _startNearbyNotifier();
    });
  }

  @override
  void dispose() {
    NearbyTuitionNotifier.instance.onMatch = null;
    NearbyTuitionNotifier.instance.stop();
    super.dispose();
  }

  /// Starts the in-app watcher that pops up when a tuition in the teacher's
  /// expected area appears. Offline/system notifications are handled separately
  /// (see NOTIFICATIONS_SETUP.md).
  void _startNearbyNotifier() {
    final notifier = NearbyTuitionNotifier.instance;
    notifier.onMatch = _showNearbyPopup;
    notifier.start();
  }

  void _showNearbyPopup(Map<String, dynamic> t) {
    if (!mounted) return;
    final area = (t['area'] ?? t['location'] ?? '').toString();
    final city = (t['city'] ?? t['district'] ?? '').toString();
    final code = (t['tuition_code'] ?? t['code'] ?? '').toString();
    final salary = (t['salary'] ?? t['salary_amount'] ?? '').toString();
    final id = t['id'];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.notifications_active, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Expanded(child: Text('New Tuition Near You')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (code.isNotEmpty)
              Text(code,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              [area, city].where((s) => s.isNotEmpty).join(', '),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (salary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('৳$salary/month',
                  style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Dismiss'),
          ),
          if (id is int)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TuitionDetailScreen(tuitionId: id),
                  ),
                );
              },
              child: const Text('View'),
            ),
        ],
      ),
    );
  }

  /// Asks the teacher to confirm before signing out, then clears the session
  /// and returns to the login screen. Prevents accidental taps on the logout
  /// icon from ending the session with no warning.
  Future<void> _confirmLogout() async {
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

    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigateTab: _goToTab),
      const TuitionListScreen(),
      const DemoDashboardScreen(),
      const GuardianListScreen(),
      const PaymentScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('BDTuition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Tuitions'),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: 'Demo'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Guardians'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
