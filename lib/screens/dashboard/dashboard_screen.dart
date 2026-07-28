import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/teacher_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeacherProvider>(context, listen: false).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.dashboardData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = provider.dashboardData;
        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load dashboard'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => provider.loadDashboard(), child: const Text('Retry')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadDashboard(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: data['personal_photo'] != null
                            ? NetworkImage(data['personal_photo'])
                            : null,
                        child: data['personal_photo'] == null ? const Icon(Icons.person, size: 30) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${data['teacher_name']}!',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code: ${data['teacher_code']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                data['status'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats cards
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.school,
                      label: 'Active Tuitions',
                      value: '${data['active_assignments'] ?? 0}',
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.book_online,
                      label: 'Available',
                      value: '${data['available_tuitions'] ?? 0}',
                      color: AppTheme.successColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.attach_money,
                      label: 'Total Paid',
                      value: '৳${data['total_earnings'] ?? 0}',
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.pending_actions,
                      label: 'Pending Due',
                      value: '৳${data['pending_due'] ?? 0}',
                      color: AppTheme.errorColor,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Applications
                const Text('Recent Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (data['recent_applications'] != null && (data['recent_applications'] as List).isNotEmpty)
                  ...List.generate((data['recent_applications'] as List).length, (i) {
                    final app = data['recent_applications'][i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: app['status'] == 'Pending' ? AppTheme.warningColor : AppTheme.successColor,
                          child: Icon(
                            app['status'] == 'Pending' ? Icons.hourglass_bottom : Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(app['tuition_code'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('${app['area']}, ${app['city']} - ৳${app['salary']}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: app['status'] == 'Pending' ? Colors.orange[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            app['status'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: app['status'] == 'Pending' ? AppTheme.warningColor : AppTheme.successColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No recent applications', style: TextStyle(color: AppTheme.textSecondary))),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
