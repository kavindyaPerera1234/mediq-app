import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/patient_bottom_nav_bar.dart';
import 'caregiver_setup_screen.dart';
import 'patient_home_screen.dart';
import 'patient_profile_screen.dart';
import '../../auth_live_queue_module3/screens/queue/live_queue_main_screen.dart';
import '../../auth_live_queue_module3/services/live_queue_service.dart';
import '../../auth_live_queue_module3/models/queue_entry_model.dart';
import '../../auth_live_queue_module3/screens/states/your_turn_fullscreen_screen.dart';
import '../../token_lifecycle_notification_module2/screens/notification_centre_screen.dart';

class PatientMainScreen extends StatefulWidget {
  final int initialIndex;
  const PatientMainScreen({super.key, this.initialIndex = 0}); // Default to Tab 0 (Home)

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  late int _currentIndex;
  StreamSubscription<PatientQueueStatus>? _statusSub;
  VoidCallback? _queueListener;
  String? _lastCalledTokenPushed;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _setupTurnNotificationListener();
  }

  void _setupTurnNotificationListener() {
    final queue = LiveQueueService();
    _statusSub = queue.statusChanges.listen((status) {
      if (status == PatientQueueStatus.called) {
        _triggerYourTurnScreen(queue);
      }
    });

    _queueListener = () {
      if (queue.myEntry.status == PatientQueueStatus.called) {
        _triggerYourTurnScreen(queue);
      }
    };
    queue.addListener(_queueListener!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (queue.myEntry.status == PatientQueueStatus.called) {
        _triggerYourTurnScreen(queue);
      }
    });
  }

  void _triggerYourTurnScreen(LiveQueueService queue) {
    if (!mounted) return;
    final token = queue.myEntry.tokenCode;
    if (token.isNotEmpty && _lastCalledTokenPushed == token) return;
    _lastCalledTokenPushed = token.isNotEmpty ? token : 'A-CALLED';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const YourTurnFullscreenScreen()),
    );
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    if (_queueListener != null) {
      LiveQueueService().removeListener(_queueListener!);
    }
    super.dispose();
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