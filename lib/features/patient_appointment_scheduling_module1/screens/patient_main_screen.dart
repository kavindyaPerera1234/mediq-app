import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/patient_bottom_nav_bar.dart';
import 'caregiver_setup_screen.dart';
import 'senior_mode_settings_screen.dart';
import '../../auth_live_queue_module3/screens/queue/live_queue_main_screen.dart';

class PatientMainScreen extends StatefulWidget {
  final int initialIndex;
  const PatientMainScreen({super.key, this.initialIndex = 1}); // Default to Tab 1 (Appointments)

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
      _buildPlaceholder(
        title: 'MediQ Hospital Portal',
        module: 'Shared Home & Government OPD Announcements',
        icon: Icons.local_hospital_outlined,
      ), // Tab 0: Home
      const CaregiverSetupScreen(), // Tab 1: Appointments (Member 1 - Booking)
      const LiveQueueMainScreen(), // Tab 2: Queue (Member 3)
      _buildPlaceholder(
        title: 'SMS & Reminders',
        module: 'Module 2: Notifications & Alerts',
        icon: Icons.notifications_none_outlined,
      ), // Tab 3: Alerts
      const SeniorModeSettingsScreen(), // Tab 4: Profile & Senior Mode Settings
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

  Widget _buildPlaceholder({
    required String title,
    required String module,
    required IconData icon,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
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
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                module,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  'Connected to Shared Firestore Architecture',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}