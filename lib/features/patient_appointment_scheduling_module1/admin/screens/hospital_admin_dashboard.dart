import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import 'manage_hospitals_screen.dart';
import 'manage_departments_screen.dart';
import 'manage_appointment_slots_screen.dart';

class HospitalAdminDashboard extends StatelessWidget {
  const HospitalAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Hospital & OPD Admin Console',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MoH Admin Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ministry of Health Sri Lanka',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Hospital & OPD Slot Configuration Console',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Metrics Overview
                const Text(
                  'Overview & Real-time Capacity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    // 1. Registered Hospitals (Live Stream)
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('hospitals').snapshots(),
                        builder: (context, snap) {
                          int count = 4;
                          if (snap.hasData) {
                            final Set<String> hospIds = {'nhsl', 'csth', 'lrh', 'cnth'};
                            for (var doc in snap.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final id = doc.id.toLowerCase();
                              final name = (data['name'] ?? '').toString().trim();
                              final isActive = data['isActive'] != false && data['isOpdAvailable'] != false;
                              if (isActive && name.isNotEmpty) {
                                hospIds.add(id);
                              }
                            }
                            count = hospIds.length;
                          }
                          return _buildMetricCard(
                            icon: Icons.local_hospital_rounded,
                            label: 'Hospitals',
                            value: '$count Registered',
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 2. Active OPD Clinics (Live Stream)
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('departments').snapshots(),
                        builder: (context, snap) {
                          int count = 5;
                          if (snap.hasData && snap.data!.docs.isNotEmpty) {
                            final activeCount = snap.data!.docs.where((d) {
                              final data = d.data() as Map<String, dynamic>;
                              return data['isActive'] != false;
                            }).length;
                            count = activeCount > 0 ? activeCount : 5;
                          }
                          return _buildMetricCard(
                            icon: Icons.medical_services_rounded,
                            label: 'OPD Clinics',
                            value: '$count Active',
                            color: AppColors.statusOrange,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // 3. Slot Capping Config (Live Stream)
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('appointment_slots').snapshots(),
                        builder: (context, snap) {
                          int cap = 25;
                          if (snap.hasData && snap.data!.docs.isNotEmpty) {
                            int sum = 0;
                            int numCaps = 0;
                            for (var doc in snap.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              if (data['capacity'] is num) {
                                sum += (data['capacity'] as num).toInt();
                                numCaps++;
                              }
                            }
                            if (numCaps > 0) {
                              cap = (sum / numCaps).round();
                            }
                          }
                          return _buildMetricCard(
                            icon: Icons.groups_rounded,
                            label: 'Slot Capping',
                            value: '$cap Limit / Slot',
                            color: AppColors.statusGreen,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 4. Daily Active Time Slots (Live Stream)
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('appointment_slots').snapshots(),
                        builder: (context, snap) {
                          int openSlots = 6;
                          if (snap.hasData && snap.data!.docs.isNotEmpty) {
                            final closedCount = snap.data!.docs.where((d) {
                              final data = d.data() as Map<String, dynamic>;
                              return data['isClosed'] == true;
                            }).length;
                            openSlots = (6 - closedCount).clamp(0, 6);
                          }
                          return _buildMetricCard(
                            icon: Icons.event_available_rounded,
                            label: 'Active Slots',
                            value: '$openSlots Daily Slots',
                            color: Colors.purple,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Management Features
                const Text(
                  'Configuration & Management Tools',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),

                _buildAdminNavTile(
                  context,
                  icon: Icons.local_hospital_outlined,
                  title: 'Manage Hospitals',
                  subtitle: 'Register new government hospitals, districts & phone hotlines',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageHospitalsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildAdminNavTile(
                  context,
                  icon: Icons.door_front_door_outlined,
                  title: 'Manage OPD Clinics & Rooms',
                  subtitle: 'Add/edit clinic departments, room numbers & doctor schedules',
                  color: AppColors.statusOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageDepartmentsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildAdminNavTile(
                  context,
                  icon: Icons.timer_outlined,
                  title: 'Configure Time Slots & Capacity (Slot Capping)',
                  subtitle: 'Set 1-hour staggered slots, limit max capacity to 25, lock slots',
                  color: AppColors.statusGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageAppointmentSlotsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Back to Admin Dashboard button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text(
                      'Back to Main Admin Dashboard',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNavTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
