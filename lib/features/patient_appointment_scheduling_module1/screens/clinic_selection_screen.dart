import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_accessibility.dart';
import '../../../../core/constants/app_translations.dart';
import '../backend/backend.dart';
import 'date_selection_screen.dart';

class ClinicSelectionScreen extends StatelessWidget {
  final GovernmentHospital hospital;
  final bool isCaregiverBooking;
  final String patientName;
  final String patientNic;
  final String relationship;
  final String priority;

  const ClinicSelectionScreen({
    super.key,
    required this.hospital,
    this.isCaregiverBooking = false,
    this.patientName = 'Patient',
    this.patientNic = 'N/A',
    this.relationship = 'Self',
    this.priority = 'normal',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppAccessibility.isHighContrastMode,
        AppAccessibility.currentLanguage,
      ]),
      builder: (context, _) {
        final isDark = AppAccessibility.isHighContrastMode.value;
        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: Text(
              AppTranslations.tr('availableDepartments'),
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
                  // Segmented 5-Step Stepper (Step 3 of 5)
                  _buildSegmentedStepper(context),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selected Hospital Summary Card
                          _buildHospitalSummaryCard(),

                          const SizedBox(height: 16),

                          Text(
                            AppTranslations.tr('availableDepartments'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.headingText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppTranslations.tr('availableDepartmentsSubtitle'),
                            style: TextStyle(fontSize: 13, color: AppColors.bodyText, height: 1.3),
                          ),
                          const SizedBox(height: 16),

                          // Clinics List
                          Expanded(
                            child: hospital.clinics.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.local_hospital_outlined, size: 56, color: AppColors.bodyText.withValues(alpha: 0.5)),
                                          const SizedBox(height: 14),
                                          Text(
                                            'No OPD Clinics Registered',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headingText),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'No clinics have been added for this hospital in Firestore yet.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 13, color: AppColors.bodyText),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: hospital.clinics.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final clinic = hospital.clinics[index];
                                      return _buildClinicCard(context, clinic, index);
                                    },
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

  // Segmented 5-Step Stepper (Steps 1 & 2 Green, Step 3 Blue Active, Steps 4 & 5 Grey)
  Widget _buildSegmentedStepper(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.tr('step3Title'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentColor,
                ),
              ),
              Text(
                AppTranslations.tr('nextDate'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5 Segments with interactive navigation
          Row(
            children: [
              _buildStepSegment(
                step: 1,
                label: 'Patient',
                isActive: false,
                isCompleted: true,
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.settings.name == 'CaregiverSetup' || route.isFirst);
                },
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 2,
                label: 'Hospital',
                isActive: false,
                isCompleted: true,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 3,
                label: 'Clinic',
                isActive: true,
                isCompleted: false,
                onTap: null,
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 4,
                label: 'Date',
                isActive: false,
                isCompleted: false,
                onTap: null,
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 5,
                label: 'Slot',
                isActive: false,
                isCompleted: false,
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepSegment({
    required int step,
    required String label,
    required bool isActive,
    required bool isCompleted,
    VoidCallback? onTap,
  }) {
    final color = isActive
        ? AppColors.accentColor
        : isCompleted
            ? AppColors.statusGreen
            : AppColors.cardBorder;

    return Expanded(
      child: Tooltip(
        message: 'Step $step: $label${isCompleted ? ' (Tap to edit)' : ''}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$step. $label',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? AppColors.accentColor : (isCompleted ? AppColors.headingText : AppColors.bodyText),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Selected Hospital Summary Card
  Widget _buildHospitalSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark ? Colors.black26 : AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.domain_rounded,
              color: AppColors.accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppTranslations.tr('selectedHospital'),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  hospital.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headingText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hospital.location,
                  style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.statusGreen, size: 20),
        ],
      ),
    );
  }

  // Polished Clinic Card
  Widget _buildClinicCard(BuildContext context, OpdClinic clinic, int index) {
    final roomNumber = 'OPD Room 0${index + 1}';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'DateSelection'),
            builder: (context) => DateSelectionScreen(
              hospital: hospital,
              clinic: clinic,
              isCaregiverBooking: isCaregiverBooking,
              patientName: patientName,
              patientNic: patientNic,
              relationship: relationship,
              priority: priority,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Specialty Medical Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                clinic.icon,
                color: AppColors.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Clinic Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinic.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.headingText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: AppColors.bodyText),
                      const SizedBox(width: 4),
                      Text(
                        clinic.hours,
                        style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusGreenLight,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.fiber_manual_record_rounded, size: 8, color: AppColors.statusGreen),
                            SizedBox(width: 4),
                            Text(
                              'Open Today',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.statusGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.innerCardBg,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          roomNumber,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.bodyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.bodyText,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}