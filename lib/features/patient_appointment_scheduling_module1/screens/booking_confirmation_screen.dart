import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../backend/backend.dart';
import 'patient_main_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final GovernmentHospital hospital;
  final OpdClinic clinic;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String tokenNumber;
  final String patientName;
  final String patientNic;
  final bool isCaregiverBooking;
  final String relationship;
  final String priority;

  const BookingConfirmationScreen({
    super.key,
    required this.hospital,
    required this.clinic,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.tokenNumber,
    this.patientName = 'Sandeepani Perera',
    this.patientNic = '200164801234',
    this.isCaregiverBooking = false,
    this.relationship = 'Self',
    this.priority = 'normal',
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Appointment Confirmed',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      // 1. Success Circle Checkmark
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.statusGreen.withValues(alpha: 0.12),
                          border: Border.all(color: AppColors.statusGreen.withValues(alpha: 0.3), width: 2),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.statusGreen,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Success Headings
                      const Text(
                        'Appointment Confirmed!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your OPD digital appointment token has been recorded.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),

                      // 3. Digital Token Pass Ticket Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textDark.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Ticket Top: Hospital & Token
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.35),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'OPD QUEUE TOKEN',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.statusGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '● ACTIVE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.statusGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Big Token Code
                                  Text(
                                    tokenNumber,
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${clinic.name} • ${clinic.roomNumber}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Dotted Divider Mockup
                            Row(
                              children: List.generate(
                                30,
                                (index) => Expanded(
                                  child: Container(
                                    color: index % 2 == 0 ? Colors.transparent : AppColors.border,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            // Ticket Body: Patient & Schedule details
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  _buildDetailRow('Patient', patientName),
                                  const SizedBox(height: 10),
                                  _buildDetailRow('NIC Number', patientNic),
                                  const SizedBox(height: 10),
                                  _buildDetailRow('Hospital', hospital.name),
                                  const SizedBox(height: 10),
                                  _buildDetailRow('Appointment Date', formattedDate),
                                  const SizedBox(height: 10),
                                  _buildDetailRow('Allocated Slot', selectedTimeSlot),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Instructions Callout
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hospital Arrival Guidance',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '• Please arrive at least 15 minutes before your time slot.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              '• Present this token screen to the OPD Nurse at Room counter.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              '• If delayed, your appointment can be tracked live in Member 3 Queue Tracker.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Pinned Bottom Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textDark.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: const Text('Save Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Token $tokenNumber saved. Confirmation SMS queued to registered mobile.'),
                                      backgroundColor: AppColors.statusGreen,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PatientMainScreen(initialIndex: 4),
                                    ),
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryLight,
                                  foregroundColor: AppColors.primaryDark,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'My Profile',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
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
                            foregroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Back to Hospital Home',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }
}