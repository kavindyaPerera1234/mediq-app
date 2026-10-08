import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../services/live_queue_service.dart';
import '../../models/queue_entry_model.dart';
import '../states/your_turn_fullscreen_screen.dart';

class QueueJourneyMapScreen extends StatelessWidget {
  const QueueJourneyMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueService = LiveQueueService();

    return AnimatedBuilder(
      animation: queueService,
      builder: (context, _) {
        final session = queueService.session;
        final myEntry = queueService.myEntry;
        final status = myEntry.status;

        final bool isWaiting = status == PatientQueueStatus.waiting ||
            status == PatientQueueStatus.approaching ||
            status == PatientQueueStatus.delayed;
        final bool isCalled = status == PatientQueueStatus.called;
        final bool isCompleted = status == PatientQueueStatus.completed;

        final token = myEntry.tokenCode.isNotEmpty ? myEntry.tokenCode : 'A-001';
        final room = session.roomNumber.isNotEmpty ? session.roomNumber : 'OPD Room 01';
        final doctor = session.doctorName.isNotEmpty ? session.doctorName : 'Duty Medical Officer';
        final dept = session.departmentName.isNotEmpty ? session.departmentName : 'OPD Clinic';
        final waitMins = myEntry.estimatedWaitMinutes;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Queue Journey Map',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
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
                    'Your OPD Clinic Roadmap',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time checkpoints for Token $token at $dept ($room).',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),

                  const SizedBox(height: 28),

                  // Journey Step 1: Hospital Main Gate (Done)
                  _buildJourneyStep(
                    stepNum: '1',
                    title: 'Hospital Main Gate & Security Check',
                    subtitle: 'Token verified on digital pass • Access approved',
                    location: 'Main Gate OPD Entrance',
                    isCompleted: true,
                    isCurrent: false,
                    isLast: false,
                  ),

                  // Journey Step 2: Triage Desk (Done)
                  _buildJourneyStep(
                    stepNum: '2',
                    title: 'Triage Desk & Vitals Check',
                    subtitle: 'Nursing officer recorded vital signs & symptoms',
                    location: 'Counter 02 - OPD Triage Area',
                    isCompleted: true,
                    isCurrent: false,
                    isLast: false,
                  ),

                  // Journey Step 3: OPD Waiting Lounge (CURRENT if waiting)
                  _buildJourneyStep(
                    stepNum: '3',
                    title: isWaiting
                        ? 'OPD Waiting Lounge (YOU ARE HERE)'
                        : 'OPD Waiting Lounge',
                    subtitle: isWaiting
                        ? 'Token $token in live queue • ~$waitMins mins estimated remaining'
                        : 'Waiting completed • Proceeded to consultation',
                    location: 'Waiting Area opposite $room',
                    isCompleted: isCalled || isCompleted,
                    isCurrent: isWaiting,
                    isLast: false,
                  ),

                  // Journey Step 4: Doctor Consultation (CURRENT if called)
                  _buildJourneyStep(
                    stepNum: '4',
                    title: isCalled
                        ? 'Doctor Consultation (YOU ARE CALLED!)'
                        : 'Doctor Consultation',
                    subtitle: isCalled
                        ? 'Consultation in progress with $doctor in $room'
                        : 'Examination with $doctor',
                    location: room,
                    isCompleted: isCompleted,
                    isCurrent: isCalled,
                    isLast: false,
                  ),

                  // Journey Step 5: Pharmacy & Medication (CURRENT if completed)
                  _buildJourneyStep(
                    stepNum: '5',
                    title: isCompleted
                        ? 'Hospital Pharmacy (YOU ARE HERE)'
                        : 'Hospital Pharmacy / Medication',
                    subtitle: 'Free government medicine collection with doctor prescription',
                    location: 'Ground Floor Pharmacy Counters 01–06',
                    isCompleted: false,
                    isCurrent: isCompleted,
                    isLast: true,
                  ),

                  const SizedBox(height: 24),

                  // If called, show an urgent alert button
                  if (isCalled) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const YourTurnFullscreenScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.record_voice_over_rounded, color: Colors.white),
                      label: Text(
                        'Your Turn is Called! Proceed to $room',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Direction Tip Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hospital Navigation Assist',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Follow the Blue Floor Line to reach $room and Pharmacy directly.',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJourneyStep({
    required String stepNum,
    required String title,
    required String subtitle,
    required String location,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color badgeColor = isCompleted
        ? AppColors.success
        : (isCurrent ? AppColors.primary : AppColors.textMuted);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step timeline indicator column
          Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : (isCompleted ? AppColors.successLight : AppColors.surface),
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 2),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: AppColors.success, size: 20)
                      : Text(
                          stepNum,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isCurrent ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    color: isCompleted ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent ? AppColors.primary : AppColors.border,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isCurrent ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'HERE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
