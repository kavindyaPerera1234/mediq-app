import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../services/live_queue_service.dart';
import '../../models/queue_entry_model.dart';

class QueueTimelineScreen extends StatelessWidget {
  const QueueTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueService = LiveQueueService();

    return AnimatedBuilder(
      animation: queueService,
      builder: (context, _) {
        final session = queueService.session;
        final myEntry = queueService.myEntry;
        final queue = queueService.queue;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Queue Timeline',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Live Activity Timeline',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time token calls and clinic progress for ${session.departmentName} (${session.roomNumber}).',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),

                  const SizedBox(height: 28),

                  // Event 1: Clinic & Doctor In Session
                  _buildTimelineEvent(
                    time: '08:30 AM',
                    title: '${session.doctorName} In Session',
                    detail: '${session.departmentName} opened for consultations in ${session.roomNumber}.',
                    icon: Icons.meeting_room_outlined,
                    isPast: true,
                  ),

                  // Event 2: Clinic Delay (if delayed)
                  if (session.isDelayed)
                    _buildTimelineEvent(
                      time: 'Active Delay',
                      title: 'Queue Delay (+${session.delayMinutes} mins)',
                      detail: session.delayReason ?? 'Emergency clinical case being attended.',
                      icon: Icons.warning_amber_rounded,
                      isTarget: false,
                      isCurrent: false,
                      isPast: false,
                      customColor: AppColors.warning,
                      customLightColor: AppColors.statusOrangeLight,
                    ),

                  // Event 3: Now Serving Current Token
                  _buildTimelineEvent(
                    time: 'NOW',
                    title: 'NOW SERVING: Token ${session.currentTokenServing}',
                    detail: 'Consultation currently in progress with ${session.doctorName}.',
                    icon: Icons.person_pin_circle_rounded,
                    isPast: false,
                    isCurrent: true,
                  ),

                  // If we have queue entries from Firestore, display them
                  if (queue.isNotEmpty) ...[
                    ...queue.map((entry) {
                      final isMyToken = entry.tokenCode == myEntry.tokenCode;
                      final isServing = entry.tokenCode == session.currentTokenServing;
                      final isDone = entry.status == PatientQueueStatus.completed || entry.status == PatientQueueStatus.missed;

                      if (isServing) return const SizedBox.shrink(); // Already rendered in Now Serving

                      return _buildTimelineEvent(
                        time: isDone
                            ? 'Completed'
                            : (isMyToken ? 'Expected' : 'In Queue'),
                        title: isMyToken
                            ? 'YOUR TURN (Token ${entry.tokenCode})'
                            : 'Token ${entry.tokenCode}',
                        detail: isMyToken
                            ? 'Please remain near ${session.roomNumber}. ~${entry.estimatedWaitMinutes} mins remaining (${entry.peopleAhead} ahead).'
                            : 'Status: ${entry.status.name.toUpperCase()} • Position: ${entry.queuePosition}',
                        icon: isMyToken ? Icons.notifications_active_rounded : Icons.confirmation_number_outlined,
                        isPast: isDone,
                        isCurrent: false,
                        isTarget: isMyToken,
                      );
                    }),
                  ] else ...[
                    // Standard fallback sequence
                    _buildTimelineEvent(
                      time: 'Previous',
                      title: 'Prior Tokens Completed',
                      detail: 'Consultations progressing at ~${session.estimatedMinutesPerPatient} minutes per patient.',
                      icon: Icons.done_all_rounded,
                      isPast: true,
                    ),

                    _buildTimelineEvent(
                      time: '~${myEntry.estimatedWaitMinutes} mins',
                      title: 'YOUR TURN EXPECTED (Token ${myEntry.tokenCode})',
                      detail: 'Please be in Waiting Lobby opposite ${session.roomNumber}. ${myEntry.peopleAhead} patients ahead.',
                      icon: Icons.notifications_active_rounded,
                      isPast: false,
                      isTarget: true,
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineEvent({
    required String time,
    required String title,
    required String detail,
    required IconData icon,
    bool isPast = false,
    bool isCurrent = false,
    bool isTarget = false,
    Color? customColor,
    Color? customLightColor,
  }) {
    Color pointColor = customColor ??
        (isTarget
            ? AppColors.primary
            : (isCurrent ? AppColors.success : (isPast ? AppColors.textSecondary : AppColors.textMuted)));

    Color bgColor = customLightColor ??
        (isCurrent
            ? AppColors.successLight
            : (isTarget ? AppColors.primaryLight : AppColors.surface));

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time badge
          SizedBox(
            width: 72,
            child: Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isTarget ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),

          // Indicator icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: pointColor, width: 2),
            ),
            child: Icon(icon, size: 16, color: pointColor),
          ),

          const SizedBox(width: 14),

          // Event Description Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isTarget
                    ? AppColors.primaryLight.withValues(alpha: 0.5)
                    : (isCurrent ? AppColors.successLight.withValues(alpha: 0.4) : AppColors.surface),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTarget ? AppColors.primary : (isCurrent ? AppColors.success : AppColors.border),
                  width: isTarget || isCurrent ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isTarget ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
