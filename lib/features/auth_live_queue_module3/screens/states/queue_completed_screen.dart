import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../services/live_queue_service.dart';
import '../../../patient_appointment_scheduling_module1/screens/patient_main_screen.dart';
import '../../../patient_appointment_scheduling_module1/screens/hospital_selection_screen.dart';

class QueueCompletedScreen extends StatelessWidget {
  const QueueCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueService = LiveQueueService();
    final session = queueService.session;
    final myEntry = queueService.myEntry;

    final token = myEntry.tokenCode.isNotEmpty ? myEntry.tokenCode : 'A-001';
    final patient = myEntry.patientName.isNotEmpty ? myEntry.patientName : 'Patient';
    final room = session.roomNumber.isNotEmpty ? session.roomNumber : 'OPD Room 01';
    final doctor = session.doctorName.isNotEmpty ? session.doctorName : 'Duty Medical Officer';
    final dept = session.departmentName.isNotEmpty ? session.departmentName : 'OPD Clinic';
    final hospital = session.hospitalName.isNotEmpty ? session.hospitalName : 'National Hospital of Sri Lanka';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success, width: 3),
                  ),
                  child: const Center(
                    child: Icon(Icons.verified_rounded, color: AppColors.success, size: 52),
                  ),
                ),
              ),

              const SizedBox(height: 20),

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
                'Thank you for visiting $hospital. Your consultation with $doctor is successfully completed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),

              const SizedBox(height: 24),

              // Visit Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Token Number', token),
                    const Divider(height: 20, color: AppColors.border),
                    _buildSummaryRow('Patient Name', patient),
                    const Divider(height: 20, color: AppColors.border),
                    _buildSummaryRow('Clinic & Room', '$dept ($room)'),
                    const Divider(height: 20, color: AppColors.border),
                    _buildSummaryRow('Attending Doctor', doctor),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Next Stop: Hospital Pharmacy Reminder
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded, color: AppColors.primary, size: 30),
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

              const SizedBox(height: 28),

              // Return to Dashboard Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientMainScreen(initialIndex: 0),
                    ),
                    (route) => false,
                  );
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

              // Book Follow-up Button (Module 1 connection)
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HospitalSelectionScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Book Another / Follow-up OPD Appointment',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
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
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
