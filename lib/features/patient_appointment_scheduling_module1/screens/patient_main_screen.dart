import 'package:flutter/material.dart';
import '../../../core/widgets/patient_bottom_nav_bar.dart';
import 'caregiver_setup_screen.dart';
import 'patient_home_screen.dart';
import 'patient_profile_screen.dart';
import '../../auth_live_queue_module3/screens/queue/live_queue_main_screen.dart';
import '../../token_lifecycle_notification_module2/screens/notification_centre_screen.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    // 5 Tabs aligned with PatientBottomNavBar
    final List<Widget> pages = [
      PatientHomeScreen(
        onNavigateTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ), // Tab 0: Home (Member 1)
      const CaregiverSetupScreen(), // Tab 1: Book OPD Appointments (Member 1)
      const LiveQueueMainScreen(), // Tab 2: Live Queue (Member 3)
      const NotificationCentreScreen(), // Tab 3: Alerts & Digital Tokens (Member 2)
      const PatientProfileScreen(), // Tab 4: Profile & Senior Accessibility (Member 1)
    ];

    return Scaffold(
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
  }
}