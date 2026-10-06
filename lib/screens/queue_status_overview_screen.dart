import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/queue_session.dart';
import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/statistic_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/loading_widget.dart';
import 'queue_pause_resume_screen.dart';
import 'staff_delay_communication_screen.dart';

class QueueStatusOverviewScreen extends StatefulWidget {
  final AuthService authService;
  final String queueSessionId;

  const QueueStatusOverviewScreen({
    super.key,
    required this.authService,
    this.queueSessionId = '',
  });

  @override
  State<QueueStatusOverviewScreen> createState() => _QueueStatusOverviewScreenState();
}

class _QueueStatusOverviewScreenState extends State<QueueStatusOverviewScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String get effectiveSessionId => widget.queueSessionId.isNotEmpty
      ? widget.queueSessionId
      : AppConstants.defaultQueueSessionId();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Queue Overview'),
      ),
      body: SafeArea(
        child: StreamBuilder<QueueSession?>(
          stream: _firestoreService.streamQueueSession(effectiveSessionId),
          builder: (context, sessionSnapshot) {
            final session = sessionSnapshot.data ??
                QueueSession(
                  queueSessionId: effectiveSessionId,
                  hospitalId: 'nhsl',
                  departmentId: 'gen_med',
                  date: DateTime.now().toString().split(' ')[0],
                  status: 'active',
                  currentTokenNumber: '—',
                );

            return StreamBuilder<List<QueueEntry>>(
              stream: _firestoreService.streamQueueEntries(effectiveSessionId),
              builder: (context, entriesSnapshot) {
                if (entriesSnapshot.connectionState == ConnectionState.waiting && !entriesSnapshot.hasData) {
                  return const LoadingWidget(message: 'Loading Queue Overview...');
                }

                final entries = entriesSnapshot.data ?? [];

                final waitingCount = entries.where((e) => e.status == 'waiting' || e.status == 'approaching' || e.status == 'rejoined').length;
                final completedCount = entries.where((e) => e.status == 'completed').length;
                final onHoldCount = entries.where((e) => e.status == 'on_hold').length;
                final skippedCount = entries.where((e) => e.status == 'missed' || e.status == 'skipped').length;
                final totalPatients = entries.length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Queue Active/Status Banner Card
                      Card(
                        color: AppColors.primaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'General Medicine OPD',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  StatusBadge(status: session.status, isLarge: true),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'CURRENT TOKEN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                session.currentTokenNumber,
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Statistics Summary Grid
                      const Text(
                        'QUEUE STATISTICS',
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
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          StatisticCard(
                            label: 'On Hold',
                            value: '$onHoldCount',
                            icon: Icons.pause_circle_filled_rounded,
                            color: AppColors.warning,
                            backgroundColor: AppColors.warningLight,
                          ),
                          const SizedBox(width: 10),
                          StatisticCard(
                            label: 'Skipped',
                            value: '$skippedCount',
                            icon: Icons.skip_next_rounded,
                            color: AppColors.error,
                            backgroundColor: AppColors.errorLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Total Patients Counter Tile
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.groups_rounded, color: AppColors.primary),
                                  SizedBox(width: 12),
                                  Text(
                                    'Total Patients Registered Today',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '$totalPatients',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Primary Actions
                      PrimaryButton(
                        label: session.status == 'paused' ? 'Resume Queue' : 'Pause Queue',
                        icon: session.status == 'paused'
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        type: session.status == 'paused' ? ButtonType.primary : ButtonType.secondary,
                        height: 52,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QueuePauseResumeScreen(
                                authService: widget.authService,
                                queueSessionId: widget.queueSessionId,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      PrimaryButton(
                        label: 'Send Delay Notification',
                        icon: Icons.access_time_filled_rounded,
                        type: ButtonType.outline,
                        height: 52,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StaffDelayCommunicationScreen(
                                authService: widget.authService,
                                queueSessionId: widget.queueSessionId,
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
    );
  }
}
