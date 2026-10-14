import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/consultation.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/consultation_admin_service.dart';
import 'manage_consultations_screen.dart';
import 'manage_doctor_allocations_screen.dart';
import 'manage_clinical_templates_screen.dart';
import '../../../../screens/staff_dashboard_screen.dart';

class DoctorConsultationAdminDashboard extends StatelessWidget {
  final AuthService? authService;

  const DoctorConsultationAdminDashboard({
    super.key,
    this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final adminService = ConsultationAdminService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Clinical Operations Admin Console',
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
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ministry of Health MoH Banner
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
                            child: const Icon(Icons.medical_information_rounded, color: Colors.white, size: 22),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Module: Doctor Consultation & Clinical Operations',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.statusGreen.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.statusGreen.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: AppColors.statusGreen),
                            SizedBox(width: 6),
                            Text(
                              'SLIIT IT3060 Evaluation Admin Mode Active',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Real-time Overview Metrics
                const Text(
                  'Clinical Operations Real-time Overview',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),

                StreamBuilder<List<Consultation>>(
                  stream: adminService.streamConsultations(),
                  builder: (context, snapshot) {
                    final list = snapshot.data ?? [];
                    final total = list.length;
                    final inProgress = list.where((c) => c.status == 'in_progress').length;
                    final completed = list.where((c) => c.status == 'completed').length;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.medical_services_rounded,
                                label: 'Total Consultations',
                                value: '$total Recorded',
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.pending_actions_rounded,
                                label: 'In Progress (Active)',
                                value: '$inProgress Patients',
                                color: AppColors.statusOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.task_alt_rounded,
                                label: 'Completed OPD',
                                value: '$completed Discharged',
                                color: AppColors.statusGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StreamBuilder<List<DoctorRoomAllocation>>(
                                stream: adminService.streamDoctorAllocations(),
                                builder: (context, allocSnap) {
                                  final allocCount = (allocSnap.data ?? []).length;
                                  return _buildMetricCard(
                                    icon: Icons.meeting_room_rounded,
                                    label: 'Doctor OPD Rooms',
                                    value: '$allocCount Active Rooms',
                                    color: Colors.purple,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Management Features
                const Text(
                  'Clinical Admin CRUD Tools',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),

                _buildAdminNavTile(
                  context,
                  icon: Icons.history_edu_rounded,
                  title: 'Manage Clinical Consultations (CRUD)',
                  subtitle: 'Create, inspect, modify prescriptions & clinical diagnosis, or archive consultation records',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageConsultationsScreen(authService: authService),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildAdminNavTile(
                  context,
                  icon: Icons.door_front_door_outlined,
                  title: 'Doctor & Room Shift Allocations (CRUD)',
                  subtitle: 'Assign doctors to OPD examination rooms, shifts and patient consultation capacity limits',
                  color: AppColors.statusOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageDoctorAllocationsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildAdminNavTile(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: 'Prescription & Diagnosis Templates (CRUD)',
                  subtitle: 'Configure standard OPD clinical protocols, ICD codes and quick prescription templates',
                  color: AppColors.statusGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageClinicalTemplatesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildAdminNavTile(
                  context,
                  icon: Icons.dashboard_customize_rounded,
                  title: 'Launch Doctor OPD Live Console',
                  subtitle: 'Switch to live clinical workstation: Call patients, hold/resume, and complete consultations',
                  color: Colors.indigo,
                  onTap: () {
                    if (authService != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StaffDashboardScreen(authService: authService!),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 28),

                // Back Button
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
