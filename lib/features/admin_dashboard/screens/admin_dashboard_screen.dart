import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_strings.dart';
import '../../patient_appointment_scheduling_module1/admin/screens/hospital_admin_dashboard.dart';
import '../../token_lifecycle_notification_module2/screens/notification_settings_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_live_queue_console_screen.dart';
import '../../../../screens/staff_dashboard_screen.dart';
import '../../../../services/auth_service.dart' as m4_auth;

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          S.adminDashboardTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded),
            tooltip: 'User Access Control',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUserManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Admin',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ministry of Health Sri Lanka • OPD Master Control',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Live Real-Time Dashboard Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.35,
              children: [
                // 1. Registered Users Count
                StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection(AppConstants.usersCollection).snapshots(),
                  builder: (context, snap) {
                    final count = snap.hasData ? snap.data!.docs.length.toString() : '...';
                    return _dashboardCard(
                      icon: Icons.people_outline_rounded,
                      title: 'Registered Users',
                      value: count,
                    );
                  },
                ),

                // 2. Today's Appointments Count
                StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection(AppConstants.appointmentsCollection).snapshots(),
                  builder: (context, snap) {
                    final count = snap.hasData ? snap.data!.docs.length.toString() : '...';
                    return _dashboardCard(
                      icon: Icons.calendar_today_outlined,
                      title: "Appointments",
                      value: count,
                    );
                  },
                ),

                // 3. Active OPD Queues
                StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection(AppConstants.queueSessionsCollection).snapshots(),
                  builder: (context, snap) {
                    final count = snap.hasData
                        ? snap.data!.docs.where((d) {
                            final data = d.data() as Map<String, dynamic>?;
                            return data?['status'] == 'active';
                          }).length.toString()
                        : '...';
                    return _dashboardCard(
                      icon: Icons.queue_outlined,
                      title: 'Active OPD Queues',
                      value: count,
                    );
                  },
                ),

                // 4. Active Queue Tokens
                StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection(AppConstants.queueEntriesCollection).snapshots(),
                  builder: (context, snap) {
                    final count = snap.hasData
                        ? snap.data!.docs.where((d) {
                            final data = d.data() as Map<String, dynamic>?;
                            final st = data?['status'];
                            return st == 'waiting' || st == 'called' || st == 'serving';
                          }).length.toString()
                        : '...';
                    return _dashboardCard(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Active Tokens',
                      value: count,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            Text(
              'Hospital Services Management',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // Card 1: Hospital & OPD Scheduling
            _managementCard(
              icon: Icons.local_hospital_outlined,
              title: S.adminAppointmentsTitle,
              subtitle: 'Manage hospitals, OPD rooms, and slot allocations',
              color: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HospitalAdminDashboard()),
                );
              },
            ),

            // Card 2: Notifications & SMS
            _managementCard(
              icon: Icons.notifications_none_rounded,
              title: S.adminTokensTitle,
              subtitle: 'Configure delay alerts, SMS gateways, and reminder rules',
              color: Colors.amber.shade800,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                );
              },
            ),

            // Card 3: User Access & Accounts
            _managementCard(
              icon: Icons.manage_accounts_outlined,
              title: S.adminUsersTitle,
              subtitle: 'Manage user profiles, patient accounts, and role permissions',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUserManagementScreen()),
                );
              },
            ),

            // Card 4: Live Queue Master Control
            _managementCard(
              icon: Icons.queue_play_next_rounded,
              title: S.adminStaffQueuesTitle,
              subtitle: 'Advance tokens, broadcast OPD clinic delays, and pause/resume queues',
              color: const Color(0xFF0284C7),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLiveQueueConsoleScreen()),
                );
              },
            ),

            // Card 5: Doctor Consultation & Clinical Portal
            _managementCard(
              icon: Icons.medical_services_outlined,
              title: 'Doctor Consultation & Clinical Operations',
              subtitle: 'Clinical console, consultation notes, and examination rooms',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StaffDashboardScreen(authService: m4_auth.AuthService())),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
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
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
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
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}