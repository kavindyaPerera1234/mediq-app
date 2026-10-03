import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/services/voice_guidance_service.dart';
import '../backend/backend.dart';
import 'booking_confirmation_screen.dart';

class AppointmentReviewScreen extends StatefulWidget {
  final GovernmentHospital hospital;
  final OpdClinic clinic;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final bool isCaregiverBooking;
  final String patientName;
  final String patientNic;
  final String relationship;
  final String priority;

  const AppointmentReviewScreen({
    super.key,
    required this.hospital,
    required this.clinic,
    required this.selectedDate,
    required this.selectedTimeSlot,
    this.isCaregiverBooking = false,
    this.patientName = 'Sandeepani Perera',
    this.patientNic = '200164801234',
    this.relationship = 'Self',
    this.priority = 'normal',
  });

  @override
  State<AppointmentReviewScreen> createState() => _AppointmentReviewScreenState();
}

class _AppointmentReviewScreenState extends State<AppointmentReviewScreen> {
  bool _isSubmitting = false;

  final AppointmentService _appointmentService = AppointmentService();
  final CaregiverService _caregiverService = CaregiverService();

  Future<void> _handleConfirmAppointment() async {
    setState(() {
      _isSubmitting = true;
    });

    final token = _appointmentService.generateTokenCode();

    final appointment = AppointmentModel(
      id: '',
      patientId: widget.patientNic,
      patientName: widget.patientName,
      patientNic: widget.patientNic,
      isCaregiverBooking: widget.isCaregiverBooking,
      relationship: widget.relationship,
      priority: widget.priority,
      hospitalId: widget.hospital.id,
      hospitalName: widget.hospital.name,
      departmentId: widget.clinic.id,
      departmentName: widget.clinic.name,
      roomNumber: widget.clinic.roomNumber,
      appointmentDate: DateFormat('yyyy-MM-dd').format(widget.selectedDate),
      timeSlot: widget.selectedTimeSlot,
      tokenCode: token,
      status: 'confirmed',
    );

    // Call dedicated Service layer
    await _appointmentService.bookAppointment(appointment);

    if (widget.isCaregiverBooking) {
      await _caregiverService.addCaregiverPatient(CaregiverPatientModel(
        id: '',
        caregiverUserId: 'user_sandeepani_001',
        patientName: widget.patientName,
        patientNic: widget.patientNic,
        relationship: widget.relationship,
        priority: widget.priority,
      ));
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    VoiceGuidanceService.speak(
      "Appointment confirmed for ${widget.patientName}. Your OPD token number is $token for room ${widget.clinic.roomNumber}.",
      context: context,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(
          hospital: widget.hospital,
          clinic: widget.clinic,
          selectedDate: widget.selectedDate,
          selectedTimeSlot: widget.selectedTimeSlot,
          tokenNumber: token,
          patientName: widget.patientName,
          patientNic: widget.patientNic,
          isCaregiverBooking: widget.isCaregiverBooking,
          relationship: widget.relationship,
          priority: widget.priority,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(widget.selectedDate);

    return ValueListenableBuilder<bool>(
      valueListenable: AppAccessibility.isHighContrastMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: const Text(
              'Review Appointment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: AppColors.appBarBg,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: isDark ? 1 : 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header card with Verified Trust badge
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.chipBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.accentColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified_user_rounded, color: AppColors.accentColor, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ministry of Health Sri Lanka',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accentColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Please review your OPD clinic appointment details carefully before final submission.',
                                        style: TextStyle(fontSize: 11, color: AppColors.bodyText),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 1. Patient Details Card
                          _buildSectionCard(
                            title: 'Patient Information',
                            icon: Icons.person_rounded,
                            children: [
                              _buildDetailRow('Patient Full Name', widget.patientName),
                              Divider(height: 18, color: AppColors.cardBorder),
                              _buildDetailRow('National ID (NIC)', widget.patientNic),
                              Divider(height: 18, color: AppColors.cardBorder),
                              _buildDetailRow(
                                'Booking Type',
                                widget.isCaregiverBooking
                                    ? 'Caregiver (${widget.relationship})'
                                    : 'Self Booking',
                              ),
                              Divider(height: 18, color: AppColors.cardBorder),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Triage Priority',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.bodyText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  _buildPriorityBadge(widget.priority),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. Clinical Booking Details Card
                          _buildSectionCard(
                            title: 'Hospital & Clinic Details',
                            icon: Icons.local_hospital_rounded,
                            children: [
                              _buildDetailRow('Hospital', widget.hospital.name),
                              Divider(height: 18, color: AppColors.cardBorder),
                              _buildDetailRow(
                                'OPD Specialty Clinic',
                                '${widget.clinic.name} (${widget.clinic.roomNumber})',
                              ),
                              Divider(height: 18, color: AppColors.cardBorder),
                              _buildDetailRow('Consultation Date', formattedDate),
                              Divider(height: 18, color: AppColors.cardBorder),
                              _buildDetailRow('Staggered Time Slot', widget.selectedTimeSlot),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. Instructions & Guidelines Callout
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: AppColors.statusOrange, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Important Arrival Guidance',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.headingText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildGuidelineItem('Arrive at the hospital 15 minutes before your slot.'),
                                _buildGuidelineItem('Present your digital token QR pass at OPD Room Counter.'),
                                _buildGuidelineItem('Bring your original National ID (NIC) or Health Clinic Card.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Confirm Button
                  _buildBottomAction(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.headingText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
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
          style: TextStyle(
            fontSize: 12,
            color: AppColors.bodyText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.headingText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color badgeColor = AppColors.statusGreen;
    Color textColor = AppColors.statusGreen;
    String label = 'STANDARD';

    if (priority == 'elderly') {
      badgeColor = AppColors.statusOrange;
      textColor = AppColors.statusOrange;
      label = 'ELDERLY 60+';
    } else if (priority == 'wheelchair') {
      badgeColor = AppColors.primary;
      textColor = AppColors.primary;
      label = 'WHEELCHAIR';
    } else if (priority == 'maternity') {
      badgeColor = Colors.purple;
      textColor = Colors.purple;
      label = 'MATERNITY';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: AppColors.bodyText, fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: AppColors.bodyText, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleConfirmAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              foregroundColor: AppColors.isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 20, color: AppColors.isDark ? Colors.black : Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}