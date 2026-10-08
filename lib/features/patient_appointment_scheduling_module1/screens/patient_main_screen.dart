import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/widgets/patient_bottom_nav_bar.dart';
import 'patient_home_screen.dart';
import 'patient_profile_screen.dart';
import '../../auth_live_queue_module3/screens/queue/live_queue_main_screen.dart';
import '../../token_lifecycle_notification_module2/screens/my_appointments_screen.dart';
import '../../token_lifecycle_notification_module2/screens/notification_centre_screen.dart';
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
        // 5 Tabs aligned with PatientBottomNavBar
        final List<Widget> pages = [
          PatientHomeScreen(
            onNavigateTab: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ), // Tab 0: Home
          const MyAppointmentsScreen(), // Tab 1: Appointments (Member 2: My Appointments)
          const LiveQueueMainScreen(), // Tab 2: Queue (Member 3)
          const NotificationCentreScreen(), // Tab 3: Alerts (Member 2: Notifications & SMS)
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
}