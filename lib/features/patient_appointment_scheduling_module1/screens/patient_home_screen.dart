import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../backend/backend.dart';
import 'caregiver_setup_screen.dart';
import 'senior_mode_settings_screen.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';
import '../../auth_live_queue_module3/screens/states/your_turn_fullscreen_screen.dart';
import '../../auth_live_queue_module3/screens/states/queue_completed_screen.dart';
import '../../token_lifecycle_notification_module2/screens/digital_token_details_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const PatientHomeScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final currentUser = AuthService().currentUser;
        final patientNic = (currentUser?.nic != null && currentUser!.nic!.trim().isNotEmpty)
            ? currentUser.nic!.trim()
            : (currentUser?.phoneNumber != null && currentUser!.phoneNumber.trim().isNotEmpty
                ? currentUser.phoneNumber.trim()
                : (currentUser?.userId != null && currentUser!.userId.isNotEmpty ? currentUser.userId : ''));
        final appointmentService = AppointmentService();

        return ValueListenableBuilder<bool>(
          valueListenable: AppAccessibility.isHighContrastMode,
          builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital_rounded, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MediQ Hospital Portal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Ministry of Health Sri Lanka',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: AppColors.appBarBg,
            elevation: isDark ? 1 : 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.accessibility_new_rounded, color: Colors.white),
                tooltip: 'Senior & Accessibility Options',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SeniorModeSettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Patient Welcome Banner
                    _buildWelcomeHeader(currentUser),
                    const SizedBox(height: 16),

                    // 2. Active Token Live Card (Streamed from Firestore)
                    StreamBuilder<List<AppointmentModel>>(
                      stream: appointmentService.streamPatientAppointments(patientNic),
                      builder: (context, snapshot) {
                        final appointments = snapshot.data ?? [];
                        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                        final activeAppointments = appointments
                            .where((a) => (a.status == 'confirmed' || a.status == 'called' || a.status == 'serving' || a.status == 'waiting') && a.appointmentDate.compareTo(todayStr) >= 0)
                            .toList();

                        if (activeAppointments.isNotEmpty) {
                          return _buildActiveTokenCard(context, activeAppointments.first);
                        } else {
                          final completedToday = appointments
                              .where((a) => (a.status == 'completed' || a.status == 'done') && a.appointmentDate == todayStr)
                              .toList();
                          if (completedToday.isNotEmpty) {
                            return _buildCompletedTodayCard(context, completedToday.first);
                          }
                          return _buildNoActiveTokenCard(context);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // 3. Quick Actions Grid
                    Text(
                      'Quick Services',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headingText),
                    ),
                    const SizedBox(height: 10),
                    _buildQuickActionsGrid(context),
                    const SizedBox(height: 20),

                    // 4. Ministry of Health Guidelines
                    Text(
                      'OPD Patient Guidelines',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headingText),
                    ),
                    const SizedBox(height: 10),
                    _buildGuidelinesCard(),
                    const SizedBox(height: 16),

                    // 5. Senior Accessibility Quick Access
                    _buildSeniorModeBanner(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }

  Widget _buildWelcomeHeader(dynamic user) {
    final rawName = user?.fullName?.toString().trim();
    final name = (rawName != null && rawName.isNotEmpty) ? rawName : 'Patient';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    final rawNic = user?.nic?.toString().trim();
    final rawPhone = user?.phoneNumber?.toString().trim();
    final idSubtitle = (rawNic != null && rawNic.isNotEmpty)
        ? 'NIC: $rawNic'
        : (rawPhone != null && rawPhone.isNotEmpty)
            ? 'Phone: $rawPhone'
            : 'Registered MediQ Patient';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.chipBg,
            child: Text(initial, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accentColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ayubowan, $name 🌿',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headingText),
                ),
                const SizedBox(height: 2),
                Text(
                  idSubtitle,
                  style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTokenCard(BuildContext context, AppointmentModel appointment) {
    final isCalled = appointment.status == 'called' || appointment.status == 'serving';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCalled
              ? [const Color(0xFF15803D), const Color(0xFF166534)]
              : [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isCalled ? const Color(0xFF15803D) : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCalled ? Colors.amber.shade400 : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCalled ? '🚨 YOUR TURN IS CALLED NOW!' : '● YOUR NEXT OPD TOKEN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCalled ? Colors.black87 : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                appointment.appointmentDate,
                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.tokenCode,
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.departmentName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${appointment.hospitalName} • ${appointment.roomNumber}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        appointment.isCaregiverBooking
                            ? '👨‍👩‍👧 For: ${appointment.patientName} (${appointment.relationship})'
                            : '👤 For: ${appointment.patientName} (Self)',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (isCalled) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const YourTurnFullscreenScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DigitalTokenDetailsScreen(
                          appointmentId: appointment.id.isNotEmpty ? appointment.id : appointment.tokenCode,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCalled ? Colors.amber.shade300 : Colors.white,
                  foregroundColor: isCalled ? Colors.black87 : AppColors.primaryDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isCalled ? 'ENTER ROOM' : 'View Pass',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTodayCard(BuildContext context, AppointmentModel appointment) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'OPD VISIT COMPLETED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                appointment.appointmentDate,
                style: TextStyle(fontSize: 12, color: AppColors.bodyText, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.tokenCode,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.headingText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.departmentName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingText),
                    ),
                    Text(
                      '${appointment.hospitalName} • Consultation Finished',
                      style: TextStyle(fontSize: 11, color: AppColors.bodyText),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QueueCompletedScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chipBg,
                  foregroundColor: AppColors.accentColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveTokenCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_available_rounded, color: AppColors.accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Active Appointment Today',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingText),
                ),
                const SizedBox(height: 2),
                Text(
                  'Book a government hospital OPD slot in 5 easy steps.',
                  style: TextStyle(fontSize: 11, color: AppColors.bodyText),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CaregiverSetupScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Book Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.28,
      children: [
        _buildActionCard(
          title: 'Book OPD Slot',
          subtitle: 'Choose hospital & time',
          icon: Icons.calendar_month_rounded,
          color: AppColors.accentColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CaregiverSetupScreen()),
          ),
        ),
        _buildActionCard(
          title: 'Live Queue',
          subtitle: 'Real-time room tracking',
          icon: Icons.format_list_numbered_rounded,
          color: AppColors.statusGreen,
          onTap: () => onNavigateTab(2),
        ),
        _buildActionCard(
          title: 'SMS Alerts',
          subtitle: 'Token notifications',
          icon: Icons.sms_outlined,
          color: AppColors.statusOrange,
          onTap: () => onNavigateTab(3),
        ),
        _buildActionCard(
          title: 'My Profile & Dependents',
          subtitle: 'Caregiver management',
          icon: Icons.person_pin_rounded,
          color: Colors.purple.shade400,
          onTap: () => onNavigateTab(4),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.headingText),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: AppColors.bodyText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelinesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _buildGuidelineRow(
            icon: Icons.schedule_rounded,
            title: 'OPD Hours: Morning 8:00 AM – 12:00 PM | Afternoon 12:00 PM – 2:00 PM',
          ),
          Divider(height: 14, color: AppColors.cardBorder),
          _buildGuidelineRow(
            icon: Icons.badge_outlined,
            title: 'Please present your Original NIC & Clinic Book upon arrival.',
          ),
          Divider(height: 14, color: AppColors.cardBorder),
          _buildGuidelineRow(
            icon: Icons.elderly_rounded,
            title: 'Priority triage lanes available for Senior Citizens (60+) & Disabled patients.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineRow({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 11.5, color: AppColors.headingText, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildSeniorModeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.accessibility_new_rounded, color: AppColors.accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Senior & Accessibility Mode',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headingText),
                ),
                Text(
                  'Large font sizes, high contrast & voice guidance',
                  style: TextStyle(fontSize: 10.5, color: AppColors.bodyText),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SeniorModeSettingsScreen()),
              );
            },
            child: Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentColor)),
          ),
        ],
      ),
    );
  }
}
