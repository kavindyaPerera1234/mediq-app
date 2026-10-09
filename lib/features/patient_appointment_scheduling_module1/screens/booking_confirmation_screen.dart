import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/constants/app_translations.dart';
import '../backend/backend.dart';
import 'patient_main_screen.dart';
import '../../token_lifecycle_notification_module2/screens/digital_token_details_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final GovernmentHospital hospital;
  final OpdClinic clinic;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String tokenNumber;
  final String appointmentId;
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
    this.appointmentId = '',
    this.patientName = 'Patient',
    this.patientNic = 'N/A',
    this.isCaregiverBooking = false,
    this.relationship = 'Self',
    this.priority = 'normal',
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(selectedDate);

    return AnimatedBuilder(
      animation: Listenable.merge([AppAccessibility.isHighContrastMode, AppAccessibility.currentLanguage]),
      builder: (context, _) {
        final isDark = AppAccessibility.isHighContrastMode.value;
        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: Text(
              AppTranslations.tr('appointmentConfirmed'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: AppColors.appBarBg,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: isDark ? 1 : 0,
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
                          Text(
                            AppTranslations.tr('appointmentConfirmed'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.headingText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppTranslations.tr('confirmedSubtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.bodyText),
                          ),
                          const SizedBox(height: 20),

                          // 3. Digital Token Pass Ticket Card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.05),
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
                                    color: AppColors.chipBg,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppTranslations.tr('tokenPass').toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                              color: AppColors.accentColor,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.statusGreen.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              AppTranslations.tr('activeStatus'),
                                              style: const TextStyle(
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
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accentColor,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${clinic.name} • ${clinic.roomNumber}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.headingText,
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
                                        color: index % 2 == 0 ? Colors.transparent : AppColors.cardBorder,
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
                                      _buildDetailRow(AppTranslations.tr('patientInfo'), patientName),
                                      const SizedBox(height: 10),
                                      _buildDetailRow(AppTranslations.tr('nicOrBirthCert').replaceAll(' *', ''), patientNic),
                                      const SizedBox(height: 10),
                                      _buildDetailRow(AppTranslations.tr('chooseHospital'), hospital.name),
                                      const SizedBox(height: 10),
                                      _buildDetailRow(AppTranslations.tr('selectedDateHeader'), formattedDate),
                                      const SizedBox(height: 10),
                                      _buildDetailRow(AppTranslations.tr('allocatedSlot'), selectedTimeSlot),
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
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTranslations.tr('arrivalGuidance'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.headingText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "• ${AppTranslations.tr('guideline1')}",
                                  style: TextStyle(fontSize: 12, color: AppColors.bodyText, height: 1.3),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "• ${AppTranslations.tr('guideline2')}",
                                  style: TextStyle(fontSize: 12, color: AppColors.bodyText, height: 1.3),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "• ${AppTranslations.tr('guideline3')}",
                                  style: TextStyle(fontSize: 12, color: AppColors.bodyText, height: 1.3),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.qr_code_rounded, size: 18),
                                    label: const Text('View Digital Token', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.accentColor,
                                      side: BorderSide(color: AppColors.accentColor),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DigitalTokenDetailsScreen(
                                            appointmentId: appointmentId.isNotEmpty ? appointmentId : tokenNumber,
                                          ),
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
                                          builder: (context) => const PatientMainScreen(initialIndex: 1),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.chipBg,
                                      foregroundColor: AppColors.accentColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(
                                      AppTranslations.tr('navAppointments'),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                                backgroundColor: AppColors.accentColor,
                                foregroundColor: AppColors.isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                AppTranslations.tr('backToHome'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.isDark ? Colors.black : Colors.white,
                                ),
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
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.bodyText, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headingText),
          ),
        ),
      ],
    );
  }
}