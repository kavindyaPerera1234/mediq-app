import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
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

  Future<void> _showAllScreensModal() async {
    final staffProfile = widget.authService.currentStaffProfile;
    final rawHId = staffProfile?.hospitalId ?? '';
    final rawDId = staffProfile?.departmentId ?? '';
    final hId = (rawHId == 'HOSP-001' || rawHId.isEmpty) ? 'nhsl' : rawHId;
    final dId = (rawDId == 'DEPT-001' || rawDId.isEmpty) ? 'gen_med' : rawDId;
    final dynamicSessionId = AppConstants.defaultQueueSessionId(hId, dId);

    final entries = await _firestoreService.getPatientQueue(dynamicSessionId);
    final activeEntry = entries.isNotEmpty ? entries.first : null;
    final sampleEntryId = activeEntry?.queueEntryId ?? '';
    final sampleToken = activeEntry?.tokenNumber ?? 'A-001';
    final sampleName = activeEntry?.patientName ?? 'Waiting Patient';

    if (!mounted) return;

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
                    'CLINICAL STAFF INTERFACES',
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
                    _buildScreenTile('1. Staff Dashboard', Icons.dashboard_rounded, () => Navigator.pop(context)),
                    _buildScreenTile('2. Patient Queue List', Icons.format_list_bulleted_rounded, () => _openScreen(PatientQueueListScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('4. Patient Queue Detail', Icons.person_search_rounded, () {
                      if (sampleEntryId.isNotEmpty) {
                        _openScreen(PatientQueueDetailScreen(authService: widget.authService, queueEntryId: sampleEntryId));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No active patients in queue. Book an appointment first!')),
                        );
                      }
                    }),
                    _buildScreenTile('5. Call Next Patient', Icons.campaign_rounded, () => _openScreen(CallNextPatientScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('6. Called Patient State', Icons.volume_up_rounded, () {
                      if (sampleEntryId.isNotEmpty) {
                        _openScreen(CalledPatientStateScreen(authService: widget.authService, queueEntryId: sampleEntryId));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No active patients in queue. Call a patient first!')),
                        );
                      }
                    }),
                    _buildScreenTile('7. Hold & Resume', Icons.pause_circle_filled_rounded, () => _openScreen(HoldAndResumeScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('8. Emergency Priority', Icons.warning_rounded, () => _openScreen(EmergencyPriorityScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('9. Queue Status Overview', Icons.pie_chart_rounded, () => _openScreen(QueueStatusOverviewScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('10. Staff Delay Communication', Icons.access_time_filled_rounded, () => _openScreen(StaffDelayCommunicationScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('11. Receptionist Queue Monitor', Icons.desktop_windows_rounded, () => _openScreen(ReceptionistQueueMonitorScreen(authService: widget.authService))),
                    _buildScreenTile('12. Queue Pause/Resume', Icons.pause_rounded, () => _openScreen(QueuePauseResumeScreen(authService: widget.authService, queueSessionId: dynamicSessionId))),
                    _buildScreenTile('13. Consultation Complete', Icons.check_circle_rounded, () => _openScreen(ConsultationCompleteScreen(authService: widget.authService, tokenNumber: sampleToken, patientName: sampleName))),
                    _buildScreenTile('14. Skip Patient Confirmation', Icons.skip_next_rounded, () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => SkipPatientConfirmationScreen(
                          authService: widget.authService,
                          queueEntryId: sampleEntryId,
                          tokenNumber: sampleToken,
                          patientName: sampleName,
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

    final rawHId = staffProfile?.hospitalId ?? '';
    final rawDId = staffProfile?.departmentId ?? '';
    final hId = (rawHId == 'HOSP-001' || rawHId.isEmpty) ? 'nhsl' : rawHId;
    final dId = (rawDId == 'DEPT-001' || rawDId.isEmpty) ? 'gen_med' : rawDId;
    final sessionId = AppConstants.defaultQueueSessionId(hId, dId);

    final staffName = staffUser?.fullName ?? 'Dr. Silva';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MediQ OPD Portal'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: _isSeeding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
            tooltip: 'Seed Reference Hospital Reference Data',
            onPressed: _isSeeding ? null : _handleSeedDatabase,
          ),
          IconButton(
            icon: const Icon(Icons.apps_rounded, color: AppColors.primary),
            tooltip: 'All 14 Screens Quick Navigator',
            onPressed: _showAllScreensModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Dashboard',
            onPressed: () {
              setState(() {});
            },
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
                  currentTokenNumber: '—',
                  lastIssuedTokenNumber: '—',
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
                    tokenNumber: session.currentTokenNumber,
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
                      const SizedBox(height: 24),

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
                                      (currentCalled.tokenNumber.isNotEmpty && currentCalled.tokenNumber != '—')
                                          ? currentCalled.tokenNumber
                                          : (session.currentTokenNumber.isNotEmpty && session.currentTokenNumber != '—'
                                              ? session.currentTokenNumber
                                              : '—'),
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
