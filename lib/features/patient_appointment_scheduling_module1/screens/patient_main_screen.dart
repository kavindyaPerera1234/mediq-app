import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/widgets/patient_bottom_nav_bar.dart';
import 'caregiver_setup_screen.dart';
import 'patient_home_screen.dart';
import 'patient_profile_screen.dart';
import '../../auth_live_queue_module3/screens/queue/live_queue_main_screen.dart';
import '../backend/backend.dart';

class PatientMainScreen extends StatefulWidget {
  final int initialIndex;
  const PatientMainScreen({super.key, this.initialIndex = 0}); // Default to Tab 0 (Home)

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    ProfileService().syncWithCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppAccessibility.isHighContrastMode,
        AppAccessibility.isSimplifiedNav,
        AppAccessibility.currentLanguage,
      ]),
      builder: (context, _) {
        final isDark = AppAccessibility.isHighContrastMode.value;

        // 5 Tabs aligned with PatientBottomNavBar
        final List<Widget> pages = [
          PatientHomeScreen(
            onNavigateTab: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ), // Tab 0: Home
          const CaregiverSetupScreen(), // Tab 1: Appointments (Member 1 - Booking)
          const LiveQueueMainScreen(), // Tab 2: Queue (Member 3)
          _buildPlaceholder(
            title: 'SMS & Reminders',
            module: 'Module 2: Notifications & Alerts',
            icon: Icons.notifications_none_outlined,
            isDark: isDark,
          ), // Tab 3: Alerts
          const PatientProfileScreen(), // Tab 4: Patient Profile, Dependents & Accessibility
        ];

        return Scaffold(
          backgroundColor: AppColors.pageBg,
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: PatientBottomNavBar(
            currentIndex: _currentIndex,
            onTabSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder({
    required String title,
    required String module,
    required IconData icon,
    required bool isDark,
  }) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.appBarBg,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: isDark ? 1 : 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF243356) : AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: AppColors.accentColor),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.headingText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                module,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2541) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF38BDF8) : Colors.blue.shade200),
                ),
                child: Text(
                  'Connected to Shared Firestore Architecture',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentColor,
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