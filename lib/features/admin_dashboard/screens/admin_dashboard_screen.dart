import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/statistic_card.dart';
import 'admin_live_queue_console_screen.dart';
import 'admin_user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AuthService authService;

  const AdminDashboardScreen({
    super.key,
    required this.authService,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Staff Logout'),
        content: const Text('Are you sure you want to log out of MediQ Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await widget.authService.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.authService.currentUserModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MediQ Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Profile Banner
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.admin_panel_settings_rounded, size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HOSPITAL SYSTEM ADMIN',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            Text(
                              currentUser?.fullName ?? 'Administrator',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              currentUser?.email ?? 'admin@mediq.lk',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'SYSTEM ANALYTICS & OVERVIEW',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  StatisticCard(
                    label: 'Clinics',
                    value: '12',
                    icon: Icons.local_hospital_rounded,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 10),
                  StatisticCard(
                    label: 'Staff Users',
                    value: '48',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.info,
                    backgroundColor: AppColors.infoLight,
                  ),
                  const SizedBox(width: 10),
                  StatisticCard(
                    label: 'Active Queues',
                    value: '8',
                    icon: Icons.playlist_add_check_circle_rounded,
                    color: AppColors.success,
                    backgroundColor: AppColors.successLight,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'ADMINISTRATION CONTROL PANELS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                          child: const Icon(Icons.monitor_heart_rounded, color: AppColors.primary),
                        ),
                        title: const Text('Master Live Queue Console', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Real-time token control, queue pause/resume & triage overrides'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminLiveQueueConsoleScreen(authService: widget.authService),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.infoLight, shape: BoxShape.circle),
                          child: const Icon(Icons.manage_accounts_rounded, color: AppColors.info),
                        ),
                        title: const Text('User Registry & Role Management', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Manage doctors, nurses, receptionists and patient accounts'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminUserManagementScreen(authService: widget.authService),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
