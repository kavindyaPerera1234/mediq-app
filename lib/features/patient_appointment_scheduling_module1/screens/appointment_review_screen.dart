import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/constants/app_translations.dart';
import '../../../core/services/voice_guidance_service.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';
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
    this.patientName = 'Patient',
    this.patientNic = 'N/A',
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

    final appDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final token = await _appointmentService.generateNextTokenCode(
      departmentId: widget.clinic.id,
      appointmentDate: appDate,
    );

    final currentUserId = AuthService().currentUser?.userId ?? 'user_patient';
    final userNic = AuthService().currentUser?.nic ?? '';
    final patientNic = widget.patientNic.isNotEmpty && widget.patientNic != 'N/A'
        ? widget.patientNic
        : (userNic.isNotEmpty ? userNic : 'N/A');

    final appointment = AppointmentModel(
      id: '',
      patientId: currentUserId,
      userId: currentUserId,
      patientName: widget.patientName,
      patientNic: patientNic,
      isCaregiverBooking: widget.isCaregiverBooking,
      relationship: widget.relationship,
      priority: widget.priority,
      hospitalId: widget.hospital.id,
      hospitalName: widget.hospital.name,
      departmentId: widget.clinic.id,
      departmentName: widget.clinic.name,
      roomNumber: widget.clinic.roomNumber,
      appointmentDate: appDate,
      timeSlot: widget.selectedTimeSlot,
      tokenCode: token,
      status: 'confirmed',
    );

    // Call dedicated Service layer
    await _appointmentService.bookAppointment(appointment);

    if (widget.isCaregiverBooking) {
      await _caregiverService.addCaregiverPatient(CaregiverPatientModel(
        id: '',
        caregiverUserId: currentUserId,
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
          appointmentId: appointment.id,
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

    return AnimatedBuilder(
      animation: Listenable.merge([AppAccessibility.isHighContrastMode, AppAccessibility.currentLanguage]),
      builder: (context, _) {
        final isDark = AppAccessibility.isHighContrastMode.value;
        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: Text(
              AppTranslations.tr('reviewTitle'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                                        AppTranslations.tr('ministryBanner'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accentColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppTranslations.tr('ministryBannerDesc'),
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
                            title: AppTranslations.tr('patientInfo'),
                            icon: Icons.person_rounded,
                            children: [
                              _buildDetailRow(AppTranslations.tr('patientFullName').replaceAll(' *', ''), widget.patientName),
                              Divider(height: 18, color: AppColors.cardBorder),
                              _buildDetailRow(AppTranslations.tr('nicOrBirthCert').replaceAll(' *', ''), widget.patientNic),
                              Divider(height: 18, color: AppColors.cardBorder),
                              _buildDetailRow(
                                AppTranslations.tr('whoIsAppointmentFor').replaceAll('?', ''),
                                widget.isCaregiverBooking
                                    ? '${AppTranslations.tr('someoneElse')} (${widget.relationship})'
                                    : AppTranslations.tr('myself'),
                              ),
                              Divider(height: 18, color: AppColors.cardBorder),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppTranslations.tr('specialPriority'),
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
                            title: AppTranslations.tr('hospitalDetails'),
                            icon: Icons.local_hospital_rounded,
                            children: [
                              _buildDetailRow(AppTranslations.tr('chooseHospital'), widget.hospital.name),
                              Divider(height: 18, color: AppColors.cardBorder),
                              _buildDetailRow(
                                AppTranslations.tr('availableDepartments'),
                                '${widget.clinic.name} (${widget.clinic.roomNumber})',
                              ),
                              Divider(height: 18, color: AppColors.cardBorder),
                              _buildDetailRow(AppTranslations.tr('selectedDateHeader'), formattedDate),
                              Divider(height: 18, color: AppColors.cardBorder),
                              _buildDetailRow(AppTranslations.tr('allocatedSlot'), widget.selectedTimeSlot),
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
                                      AppTranslations.tr('arrivalGuidance'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.headingText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildGuidelineItem(AppTranslations.tr('guideline1')),
                                _buildGuidelineItem(AppTranslations.tr('guideline2')),
                                _buildGuidelineItem(AppTranslations.tr('guideline3')),
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
    String label = AppTranslations.tr('standardPriority').toUpperCase();

    if (priority == 'elderly') {
      badgeColor = AppColors.statusOrange;
      textColor = AppColors.statusOrange;
      label = AppTranslations.tr('elderlyPriority').toUpperCase();
    } else if (priority == 'wheelchair') {
      badgeColor = AppColors.primary;
      textColor = AppColors.primary;
      label = AppTranslations.tr('wheelchairPriority').toUpperCase();
    } else if (priority == 'maternity') {
      badgeColor = Colors.purple;
      textColor = Colors.purple;
      label = AppTranslations.tr('maternityPriority').toUpperCase();
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
                        AppTranslations.tr('confirmAppointment'),
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