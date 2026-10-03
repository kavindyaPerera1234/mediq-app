import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class QueueTimelineScreen extends StatelessWidget {
  const QueueTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                'Real-time event feed of token calls and clinic progress for Room 04.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),

              const SizedBox(height: 28),

              _buildTimelineEvent(
                time: '08:30 AM',
                title: 'Token A-014 Issued',
                detail: 'Appointment confirmed and placed into General Medicine queue.',
                icon: Icons.confirmation_number_outlined,
                isPast: true,
              ),

              _buildTimelineEvent(
                time: '08:45 AM',
                title: 'Dr. H. M. Perera Checked In',
                detail: 'OPD Consultation Room 04 opened for patient consultations.',
                icon: Icons.meeting_room_outlined,
                isPast: true,
              ),

              _buildTimelineEvent(
                time: '09:00 AM',
                title: 'Morning Queue Started',
                detail: 'Token A-001 called into Room 04.',
                icon: Icons.play_arrow_rounded,
                isPast: true,
              ),

              _buildTimelineEvent(
                time: '09:35 AM',
                title: 'Tokens A-002 through A-007 Completed',
                detail: 'Consultations progressing at an average of 4 minutes per patient.',
                icon: Icons.done_all_rounded,
                isPast: true,
              ),

              _buildTimelineEvent(
                time: '09:40 AM',
                title: 'NOW SERVING: Token A-008',
                detail: 'Patient currently with Dr. Perera in Room 04.',
                icon: Icons.person_pin_circle_rounded,
                isPast: false,
                isCurrent: true,
              ),

              _buildTimelineEvent(
                time: '~10:04 AM',
                title: 'YOUR TURN EXPECTED (Token A-014)',
                detail: 'Please be in Waiting Lounge B opposite Room 04.',
                icon: Icons.notifications_active_rounded,
                isPast: false,
                isTarget: true,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
  }) {
    Color pointColor = isTarget
        ? AppColors.primary
        : (isCurrent ? AppColors.success : (isPast ? AppColors.textSecondary : AppColors.textMuted));

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
              color: isCurrent
                  ? AppColors.successLight
                  : (isTarget ? AppColors.primaryLight : AppColors.surface),
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
                    ? AppColors.primaryLight.withOpacity(0.5)
                    : (isCurrent ? AppColors.successLight.withOpacity(0.4) : AppColors.surface),
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
