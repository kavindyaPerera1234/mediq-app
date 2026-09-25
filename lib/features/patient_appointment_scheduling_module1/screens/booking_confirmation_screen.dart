import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/hospital_model.dart';
import '../../token_lifecycle_notification_module2/screens/digital_token_details_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final GovernmentHospital hospital;
  final OpdClinic clinic;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String tokenNumber;

  const BookingConfirmationScreen({
    super.key,
    required this.hospital,
    required this.clinic,
    required this.selectedDate,
    required this.selectedTimeSlot,
    this.tokenNumber = 'A-024', // Figma Token A-024
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMM').format(selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // 1. Success Circle Checkmark
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successLight,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),

              // 2. Success Headings
              Text(
                'Appointment Confirmed!',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your registration has been successfully recorded',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // 3. Queue Token Card (Figma A-024 Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Label & Confirmed Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOUR APPOINTMENT TOKEN',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'CONFIRMED',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Big Token Number: A-024
                    Text(
                      tokenNumber,
                      style: GoogleFonts.inter(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    const Divider(height: 24, color: AppColors.border),

                    // Hospital Details
                    _buildDetailRow(
                      Icons.local_hospital_outlined,
                      'HOSPITAL',
                      hospital.name,
                    ),
                    const SizedBox(height: 12),

                    // Clinic Details
                    _buildDetailRow(
                      Icons.medical_services_outlined,
                      'CLINIC / OPD',
                      clinic.name,
                    ),
                    const SizedBox(height: 12),

                    // Date & Time
                    _buildDetailRow(
                      Icons.calendar_today_outlined,
                      'DATE & TIME',
                      '$formattedDate • $selectedTimeSlot',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Patient Instructions Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Instructions',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBulletText('Arrive 15 minutes before your time slot.'),
                    const SizedBox(height: 4),
                    _buildBulletText('Bring your NIC card and any previous medical records.'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 5. View Digital Token Pass Button (Handover to Member 2!)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Show handover alert to Member 2
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                       builder: (context) => DigitalTokenDetailsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View Digital Token Pass →',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}