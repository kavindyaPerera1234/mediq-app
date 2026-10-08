import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_accessibility.dart';
import '../../models/queue_entry_model.dart';
import '../../services/live_queue_service.dart';

class EstimatedWaitingTimeScreen extends StatelessWidget {
  const EstimatedWaitingTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueService = LiveQueueService();
    final session = queueService.session;
    final myEntry = queueService.myEntry;

    final baseTime = myEntry.peopleAhead * session.estimatedMinutesPerPatient;
    final delayTime = session.delayMinutes;
    final totalTime = (myEntry.peopleAhead > 0 || myEntry.estimatedWaitMinutes > 0)
        ? (myEntry.estimatedWaitMinutes > 0 ? myEntry.estimatedWaitMinutes : (baseTime + delayTime))
        : (myEntry.status == PatientQueueStatus.called || myEntry.status == PatientQueueStatus.completed
            ? 0
            : (session.currentTokenServing == '—' || session.currentTokenServing == 'Not Started'
                ? session.estimatedMinutesPerPatient + delayTime
                : delayTime));

    return AnimatedBuilder(
      animation: Listenable.merge([
        queueService,
        AppAccessibility.isHighContrastMode,
      ]),
      builder: (context, _) {
        final isDark = AppAccessibility.isHighContrastMode.value;

        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Estimated Waiting Time',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.headingText),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.headingText),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Giant Timer Badge
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'TOTAL ESTIMATED TIME TO YOUR TURN',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '~$totalTime',
                      style: GoogleFonts.inter(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      'MINUTES REMAINING',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'How this time is calculated:',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Factor 1: Patients ahead
              _buildCalcRow(
                icon: Icons.people_outline_rounded,
                title: 'Patients Ahead of You',
                math: '${myEntry.peopleAhead} Patients',
                subtext: 'Current Serving: ${session.currentTokenServing} • Your Token: ${myEntry.tokenCode}',
              ),

              const SizedBox(height: 10),

              // Factor 2: Doctor consultation pace
              _buildCalcRow(
                icon: Icons.speed_rounded,
                title: 'Doctor Average Consultation Pace',
                math: '${session.estimatedMinutesPerPatient} Mins / Patient',
                subtext: 'Calculated from Dr. Perera\'s completed consultations today',
              ),

              const SizedBox(height: 10),

              // Factor 3: Active Delays
              _buildCalcRow(
                icon: Icons.warning_amber_rounded,
                title: 'Clinic / Emergency Delays',
                math: delayTime > 0 ? '+$delayTime Mins' : '0 Mins (On Time)',
                subtext: session.delayReason ?? 'Clinic is running on standard schedule',
                isHighlight: delayTime > 0,
              ),

              const SizedBox(height: 24),

              // Recommended Patient Action Card (Elderly & Sick friendly!)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : AppColors.primaryLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF38BDF8) : AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chair_outlined, color: AppColors.accentColor, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Comfortable Waiting Advice',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• You do not need to stand in the corridor. You may sit in Lounge B or visit the cafeteria on Ground Floor.\n'
                      '• Please return to Waiting Lounge B when estimated wait drops below 10 minutes.\n'
                      '• Free filtered drinking water and wheel-chair support are available near Counter 01.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.headingText,
                        height: 1.5,
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

  Widget _buildCalcRow({
    required IconData icon,
    required String title,
    required String math,
    required String subtext,
    bool isHighlight = false,
  }) {
    final isDark = AppAccessibility.isHighContrastMode.value;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight
            ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight ? const Color(0xFFF59E0B) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlight
                  ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A))
                  : (isDark ? const Color(0xFF243356) : AppColors.primaryLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isHighlight ? const Color(0xFFF59E0B) : AppColors.accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingText,
                      ),
                    ),
                    Text(
                      math,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isHighlight ? const Color(0xFFF59E0B) : AppColors.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtext,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.bodyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
