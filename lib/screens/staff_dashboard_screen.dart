import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/queue_session.dart';
import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/seed_data_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/statistic_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/loading_widget.dart';

import 'patient_queue_list_screen.dart';
import 'patient_queue_detail_screen.dart';
import 'call_next_patient_screen.dart';
import 'called_patient_state_screen.dart';
import 'hold_and_resume_screen.dart';
import 'emergency_priority_screen.dart';
import 'queue_status_overview_screen.dart';
import 'staff_delay_communication_screen.dart';
import 'receptionist_queue_monitor_screen.dart';
import 'queue_pause_resume_screen.dart';
import 'consultation_complete_screen.dart';
import 'skip_patient_confirmation_screen.dart';
import '../features/admin_dashboard/screens/admin_dashboard_screen.dart';
import '../features/patient_appointment_scheduling_module1/admin/screens/hospital_admin_dashboard.dart';
import '../features/auth_live_queue_module3/screens/auth/welcome_entry_screen.dart';
import '../features/auth_live_queue_module3/services/auth_service.dart' as mod3_auth;

class StaffDashboardScreen extends StatefulWidget {
  final AuthService authService;

  const StaffDashboardScreen({
    super.key,
    required this.authService,
  });

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final SeedDataService _seedDataService = SeedDataService();
  int _currentBottomNavIndex = 0;
  bool _isSeeding = false;
  DateTime _selectedDate = DateTime.now();
  String? _selectedHospitalId;
  String? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    final profile = widget.authService.currentStaffProfile;
    if (profile != null) {
      if (profile.hospitalId.isNotEmpty) _selectedHospitalId = profile.hospitalId;
      if (profile.departmentId.isNotEmpty) _selectedDepartmentId = profile.departmentId;
    }
  }

  Future<void> _pickDashboardDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Staff Logout'),
        content: const Text('Are you sure you want to log out of MediQ OPD Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await widget.authService.signOut();
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

  Future<void> _handleSeedDatabase() async {
    setState(() {
      _isSeeding = true;
    });

    final success = await _seedDataService.seedDemoData();

    setState(() {
      _isSeeding = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cloud Firestore database populated successfully!'
                : 'Failed to populate database. Check Firebase connection/rules.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showAllScreensModal() {
    final staffProfile = widget.authService.currentStaffProfile;
    final hId = staffProfile?.hospitalId ?? 'nhsl';
    final dId = staffProfile?.departmentId ?? 'gen_med';
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final dynamicSessionId = '${hId.isNotEmpty ? hId : 'nhsl'}_${dId.isNotEmpty ? dId : 'gen_med'}_$dateStr';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MODULE 4 — ALL SCREENS & ADMIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _buildScreenTile('0. Admin Dashboard Console', Icons.admin_panel_settings_rounded, () => _openScreen(AdminDashboardScreen(authService: widget.authService))),
                    _buildScreenTile('Hospital & Slot Admin Console (Module 1)', Icons.domain_rounded, () => _openScreen(const HospitalAdminDashboard())),
                    _buildScreenTile('1. Staff Dashboard', Icons.dashboard_rounded, () => Navigator.pop(context)),
                    _buildScreenTile('2. Patient Queue List', Icons.format_list_bulleted_rounded, () => _openScreen(PatientQueueListScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('4. Patient Queue Detail', Icons.person_search_rounded, () => _openScreen(PatientQueueDetailScreen(authService: widget.authService, queueEntryId: 'QE-pat-019'))),
                    _buildScreenTile('5. Call Next Patient', Icons.campaign_rounded, () => _openScreen(CallNextPatientScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('6. Called Patient State', Icons.volume_up_rounded, () => _openScreen(CalledPatientStateScreen(authService: widget.authService, queueEntryId: 'QE-pat-019'))),
                    _buildScreenTile('7. Hold & Resume', Icons.pause_circle_filled_rounded, () => _openScreen(HoldAndResumeScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('8. Emergency Priority', Icons.warning_rounded, () => _openScreen(EmergencyPriorityScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('9. Queue Status Overview', Icons.pie_chart_rounded, () => _openScreen(QueueStatusOverviewScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('10. Staff Delay Communication', Icons.access_time_filled_rounded, () => _openScreen(StaffDelayCommunicationScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('11. Receptionist Queue Monitor', Icons.desktop_windows_rounded, () => _openScreen(ReceptionistQueueMonitorScreen(authService: widget.authService))),
                    _buildScreenTile('12. Queue Pause/Resume', Icons.pause_rounded, () => _openScreen(QueuePauseResumeScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('13. Consultation Complete', Icons.check_circle_rounded, () => _openScreen(ConsultationCompleteScreen(authService: widget.authService, tokenNumber: 'A-019', patientName: 'Nimali Wijesekera'))),
                    _buildScreenTile('14. Skip Patient Confirmation', Icons.skip_next_rounded, () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => SkipPatientConfirmationScreen(
                          authService: widget.authService,
                          queueEntryId: 'QE-pat-020',
                          tokenNumber: 'A-020',
                          patientName: 'Suresh K.',
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScreenTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffUser = widget.authService.currentUserModel;
    final staffProfile = widget.authService.currentStaffProfile;

    final hId = _selectedHospitalId ?? staffProfile?.hospitalId ?? 'nhsl';
    final dId = _selectedDepartmentId ?? staffProfile?.departmentId ?? 'gen_med';
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final sessionId = '${hId.isNotEmpty ? hId : 'nhsl'}_${dId.isNotEmpty ? dId : 'gen_med'}_$dateStr';

    final staffName = (staffUser?.fullName != null && staffUser!.fullName.isNotEmpty)
        ? staffUser.fullName
        : 'OPD Medical Officer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MediQ OPD Portal'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
            tooltip: 'Pick OPD Clinic Date',
            onPressed: _pickDashboardDate,
          ),
          IconButton(
            icon: _isSeeding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
            tooltip: 'Seed Cloud Firestore Database',
            onPressed: _isSeeding ? null : _handleSeedDatabase,
          ),
          IconButton(
            icon: const Icon(Icons.apps_rounded, color: AppColors.primary),
            tooltip: 'All Screens Navigator',
            onPressed: _showAllScreensModal,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QueueSession?>(
          stream: _firestoreService.streamQueueSession(sessionId),
          builder: (context, sessionSnapshot) {
            final session = sessionSnapshot.data ??
                QueueSession(
                  queueSessionId: sessionId,
                  hospitalId: hId.isNotEmpty ? hId : 'nhsl',
                  departmentId: dId.isNotEmpty ? dId : 'gen_med',
                  date: DateTime.now().toString().split(' ')[0],
                  status: 'active',
                  currentTokenNumber: 'A-018',
                  lastIssuedTokenNumber: 'A-025',
                );

            return StreamBuilder<List<QueueEntry>>(
              stream: _firestoreService.streamQueueEntries(sessionId),
              builder: (context, entriesSnapshot) {
                if (entriesSnapshot.connectionState == ConnectionState.waiting && !entriesSnapshot.hasData) {
                  return const LoadingWidget();
                }

                final entries = entriesSnapshot.data ?? [];

                final waitingCount = entries.where((e) => e.status == 'waiting' || e.status == 'approaching' || e.status == 'rejoined').length;
                final completedCount = entries.where((e) => e.status == 'completed').length;
                final onHoldCount = entries.where((e) => e.status == 'on_hold').length;
                final totalScheduled = entries.length;

                final currentCalled = entries.firstWhere(
                  (e) => e.status == 'called' || e.status == 'in_consultation',
                  orElse: () => QueueEntry(
                    queueEntryId: '',
                    queueSessionId: sessionId,
                    appointmentId: '',
                    patientId: '',
                    tokenNumber: session.currentTokenNumber.isNotEmpty ? session.currentTokenNumber : 'A-018',
                    tokenCode: session.currentTokenNumber,
                  ),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header User Greeting Card
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.primaryLight,
                            child: const Icon(
                              Icons.person_rounded,
                              size: 30,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Good Morning,',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  staffName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: session.status, isLarge: true),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Multi-Hospital & OPD Department Dropdown Switcher
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_hospital_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('Hospital:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: ['nhsl', 'hosp_kandy', 'hosp_karapitiya'].contains(hId) ? hId : 'nhsl',
                                      isDense: true,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                      items: const [
                                        DropdownMenuItem(value: 'nhsl', child: Text('National Hospital of Sri Lanka (NHSL)')),
                                        DropdownMenuItem(value: 'hosp_kandy', child: Text('Kandy General Hospital')),
                                        DropdownMenuItem(value: 'hosp_karapitiya', child: Text('Karapitiya Teaching Hospital')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedHospitalId = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.meeting_room_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('OPD Clinic:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: ['gen_med', 'dept_pediatrics', 'dept_cardiology', 'dept_ent'].contains(dId) ? dId : 'gen_med',
                                      isDense: true,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                      items: const [
                                        DropdownMenuItem(value: 'gen_med', child: Text('General Medicine OPD')),
                                        DropdownMenuItem(value: 'dept_pediatrics', child: Text('Pediatrics OPD')),
                                        DropdownMenuItem(value: 'dept_cardiology', child: Text('Cardiology OPD')),
                                        DropdownMenuItem(value: 'dept_ent', child: Text('ENT Clinic')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedDepartmentId = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // OPD Summary Title Card
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Today's OPD Summary",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'General Medicine OPD',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Statistic Cards Row (Waiting, Completed, On Hold)
                              Row(
                                children: [
                                  StatisticCard(
                                    label: 'Waiting',
                                    value: '$waitingCount',
                                    icon: Icons.hourglass_top_rounded,
                                    color: AppColors.info,
                                    backgroundColor: AppColors.infoLight,
                                  ),
                                  const SizedBox(width: 10),
                                  StatisticCard(
                                    label: 'Completed',
                                    value: '$completedCount',
                                    icon: Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    backgroundColor: AppColors.successLight,
                                  ),
                                  const SizedBox(width: 10),
                                  StatisticCard(
                                    label: 'On Hold',
                                    value: '$onHoldCount',
                                    icon: Icons.pause_circle_filled_rounded,
                                    color: AppColors.warning,
                                    backgroundColor: AppColors.warningLight,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Open Queue Primary Action Button
                              PrimaryButton(
                                label: 'OPEN QUEUE',
                                icon: Icons.play_circle_fill_rounded,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PatientQueueListScreen(
                                        authService: widget.authService,
                                        queueSessionId: sessionId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Current Active Token Banner
                      Card(
                        color: AppColors.primaryLight,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.confirmation_number_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Token',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      currentCalled.tokenNumber.isNotEmpty ? currentCalled.tokenNumber : session.currentTokenNumber,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Total Scheduled',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    '$totalScheduled Patients',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Action Links Grid
                      const Text(
                        'QUICK OPD ACTIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              title: 'Emergency Priority',
                              icon: Icons.warning_rounded,
                              color: AppColors.error,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmergencyPriorityScreen(
                                      authService: widget.authService,
                                      queueSessionId: sessionId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              title: 'Queue Overview',
                              icon: Icons.pie_chart_rounded,
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QueueStatusOverviewScreen(
                                      authService: widget.authService,
                                      queueSessionId: sessionId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              title: 'Call Next Patient',
                              icon: Icons.campaign_rounded,
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CallNextPatientScreen(
                                      authService: widget.authService,
                                      queueSessionId: sessionId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              title: 'Patients on Hold',
                              icon: Icons.pause_circle_filled_rounded,
                              color: AppColors.warning,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HoldAndResumeScreen(
                                      authService: widget.authService,
                                      queueSessionId: sessionId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildQuickActionButton(
                        context,
                        title: 'Receptionist Queue Monitor',
                        icon: Icons.desktop_windows_rounded,
                        color: const Color(0xFF7E22CE),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReceptionistQueueMonitorScreen(
                                authService: widget.authService,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: StaffBottomNavigation(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() {
            _currentBottomNavIndex = index;
          });
          if (index == 1 || index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientQueueListScreen(
                  authService: widget.authService,
                  queueSessionId: sessionId,
                ),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StaffDelayCommunicationScreen(
                  authService: widget.authService,
                  queueSessionId: sessionId,
                ),
              ),
            );
          } else if (index == 4) {
            StaffBottomNavigation.showStaffProfileModal(context, widget.authService);
          }
        },
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
