import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/auth_service.dart';
import '../../patient_appointment_scheduling_module1/admin/screens/hospital_admin_dashboard.dart';
import '../../token_lifecycle_notification_module2/screens/notification_settings_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_live_queue_console_screen.dart';
import '../../../screens/staff_dashboard_screen.dart';
import '../../../screens/receptionist_queue_monitor_screen.dart';
import '../../auth_live_queue_module3/screens/auth/welcome_entry_screen.dart';
import '../../auth_live_queue_module3/services/auth_service.dart' as mod3_auth;

class AdminDashboardScreen extends StatefulWidget {
  final AuthService? authService;

  const AdminDashboardScreen({
    super.key,
    this.authService,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Admin Logout'),
        content: const Text('Are you sure you want to log out of MediQ Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _authService.signOut();
              await mod3_auth.AuthService().logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeEntryScreen()),
                  (route) => false,
                );
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
    final currentUser = _authService.currentUserModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'MediQ Admin Console',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
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
                'LIVE SYSTEM ANALYTICS & OVERVIEW',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              // Live Real-Time Dashboard Statistics
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  // 1. Registered Users Count
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection(AppConstants.usersCollection).snapshots(),
                    builder: (context, snap) {
                      final count = snap.hasData ? snap.data!.docs.length.toString() : '...';
                      return _dashboardStatCard(
                        icon: Icons.people_outline_rounded,
                        title: 'Registered Users',
                        value: count,
                        color: AppColors.info,
                      );
                    },
                  ),

                  // 2. Today's Appointments Count
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection(AppConstants.appointmentsCollection).snapshots(),
                    builder: (context, snap) {
                      final count = snap.hasData ? snap.data!.docs.length.toString() : '...';
                      return _dashboardStatCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Appointments',
                        value: count,
                        color: AppColors.primary,
                      );
                    },
                  ),

                  // 3. Active OPD Queues
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection(AppConstants.queueSessionsCollection).snapshots(),
                    builder: (context, snap) {
                      final count = snap.hasData
                          ? snap.data!.docs.where((d) {
                              final data = d.data() as Map<String, dynamic>?;
                              return data?['status'] == 'active';
                            }).length.toString()
                          : '...';
                      return _dashboardStatCard(
                        icon: Icons.queue_outlined,
                        title: 'Active OPD Queues',
                        value: count,
                        color: AppColors.success,
                      );
                    },
                  ),

                  // 4. Active Queue Tokens
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection(AppConstants.queueEntriesCollection).snapshots(),
                    builder: (context, snap) {
                      final count = snap.hasData
                          ? snap.data!.docs.where((d) {
                              final data = d.data() as Map<String, dynamic>?;
                              final st = data?['status'];
                              return st == 'waiting' || st == 'called' || st == 'serving';
                            }).length.toString()
                          : '...';
                      return _dashboardStatCard(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Active Tokens',
                        value: count,
                        color: Colors.amber.shade800,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'ADMINISTRATION CONTROL PANELS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              // Control Cards
              // Card 1: Module 1 — Hospital & OPD Clinic Console
              _managementCard(
                icon: Icons.local_hospital_rounded,
                title: 'Hospital & OPD Clinic Console (Module 1)',
                subtitle: 'Configure hospitals, clinic rooms & daily 25-patient appointment slot caps',
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HospitalAdminDashboard()),
                  );
                },
              ),

              // Card 2: Module 2 — Token Lifecycle & Delay Alerts
              _managementCard(
                icon: Icons.notifications_active_rounded,
                title: 'Token Lifecycle & Delay Alerts (Module 2)',
                subtitle: 'Configure clinic delay notifications, SMS gateways, and reminder rules',
                color: Colors.amber.shade800,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                  );
                },
              ),

              // Card 3: Module 3 — User Registry & Role Management
              _managementCard(
                icon: Icons.manage_accounts_rounded,
                title: 'User Registry & Role Management (Module 3)',
                subtitle: 'Manage doctors, nurses, receptionists, patient accounts & deactivations',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUserManagementScreen(authService: _authService),
                    ),
                  );
                },
              ),

              // Card 4: Module 3 — Master Live Queue Console
              _managementCard(
                icon: Icons.monitor_heart_rounded,
                title: 'Master Live Queue Console (Module 3)',
                subtitle: 'Real-time token control, queue pause/resume, triage & delay broadcasts',
                color: const Color(0xFF0284C7),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminLiveQueueConsoleScreen(authService: _authService),
                    ),
                  );
                },
              ),

              // Card 5: Module 4 (Member 4) — Doctor Consultation & Clinical Operations
              _managementCard(
                icon: Icons.medical_services_rounded,
                title: 'Doctor Consultation & Clinical Operations (Module 4)',
                subtitle: 'Doctor clinical console, consultation notes, examination rooms & patient call queue',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffDashboardScreen(authService: _authService),
                    ),
                  );
                },
              ),

              // Card 6: Module 4 (Member 4) — Receptionist Live Queue Monitor
              _managementCard(
                icon: Icons.desktop_windows_rounded,
                title: 'Receptionist Queue Monitor (Module 4)',
                subtitle: 'Live OPD desk queue monitor, check-in verification & emergency prioritization',
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceptionistQueueMonitorScreen(authService: _authService),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _managementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = AppColors.primary,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
