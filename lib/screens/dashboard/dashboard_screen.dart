import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/teacher_provider.dart';
import '../tuitions/tuition_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  /// Optional callback so tapping a stat card can switch the bottom-nav tab
  /// owned by HomeScreen. Left null when the screen is used standalone.
  final void Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

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
                      Builder(builder: (context) {
                        final photoUrl = ApiConfig.resolveImageUrl(
                            data['personal_photo'] ??
                                data['photo'] ??
                                data['image'] ??
                                data['avatar']);
                        return CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        );
                      }),
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

                // Main navigation cards. Total Paid / Pending Due now live in
                // the Payment section, and Active Tuitions in the Guardian
                // section — so the dashboard just routes to the four areas.
                Row(
                  children: [
                    _NavCard(
                      icon: Icons.book_online,
                      label: 'Tuition',
                      color: AppTheme.primaryColor,
                      onTap: () => widget.onNavigateTab?.call(1),
                    ),
                    const SizedBox(width: 12),
                    _NavCard(
                      icon: Icons.verified_user,
                      label: 'Demo',
                      color: AppTheme.secondaryColor,
                      onTap: () => widget.onNavigateTab?.call(2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _NavCard(
                      icon: Icons.people,
                      label: 'Guardian Number',
                      color: AppTheme.successColor,
                      onTap: () => widget.onNavigateTab?.call(3),
                    ),
                    const SizedBox(width: 12),
                    _NavCard(
                      icon: Icons.payment,
                      label: 'Payment',
                      color: AppTheme.accentColor,
                      onTap: () => widget.onNavigateTab?.call(4),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Applied / Recent Applications
                const Text('Recent Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (data['recent_applications'] != null && (data['recent_applications'] as List).isNotEmpty)
                  ...List.generate((data['recent_applications'] as List).length, (i) {
                    final app = data['recent_applications'][i];
                    final tuitionId = app['tuition_id'] ??
                        app['id'] ??
                        app['tuition']?['id'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: tuitionId != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TuitionDetailScreen(
                                      tuitionId: tuitionId is int
                                          ? tuitionId
                                          : int.tryParse('$tuitionId') ?? 0,
                                    ),
                                  ),
                                );
                              }
                            : null,
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

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
