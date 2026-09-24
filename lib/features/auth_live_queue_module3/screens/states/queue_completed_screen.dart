import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../services/live_queue_service.dart';

class QueueCompletedScreen extends StatelessWidget {
  const QueueCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueService = LiveQueueService();
    final session = queueService.session;
    final myEntry = queueService.myEntry;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),

              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success, width: 3),
                  ),
                  child: const Center(
                    child: Icon(Icons.verified_rounded, color: AppColors.success, size: 56),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'OPD Visit Completed!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for visiting ${session.hospitalName}. Your consultation with ${session.doctorName} is successfully completed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),

              const SizedBox(height: 32),

              // Visit Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Token Number', myEntry.tokenCode),
                    const Divider(height: 20, color: AppColors.border),
                    _buildSummaryRow('Patient Name', myEntry.patientName),
                    const Divider(height: 20, color: AppColors.border),
                    _buildSummaryRow('Clinic & Room', '${session.departmentName} (${session.roomNumber})'),
                    const Divider(height: 20, color: AppColors.border),
                    _buildSummaryRow('Attending Doctor', session.doctorName),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Next Stop: Hospital Pharmacy Reminder
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded, color: AppColors.primary, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Step: Free Pharmacy Collection',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Take your doctor-signed prescription to Ground Floor Pharmacy Counters 01–06.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Done Button
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: Text(
                  'Back to Home Dashboard',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
