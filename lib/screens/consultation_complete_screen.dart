import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/auth_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';
import 'call_next_patient_screen.dart';
import 'patient_queue_list_screen.dart';

class ConsultationCompleteScreen extends StatelessWidget {
  final AuthService authService;
  final String tokenNumber;
  final String patientName;
  final String queueSessionId;

  const ConsultationCompleteScreen({
    super.key,
    required this.authService,
    required this.tokenNumber,
    required this.patientName,
    this.queueSessionId = '',
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSessionId = queueSessionId.isNotEmpty
        ? queueSessionId
        : AppConstants.defaultQueueSessionId();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation Status'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Hero Container
              Container(
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.success, width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Consultation Completed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TOKEN $tokenNumber',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const StatusBadge(status: 'completed', isLarge: true),
                    const SizedBox(height: 16),
                    const Text(
                      'The consultation has been successfully completed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Action Buttons
              PrimaryButton(
                label: 'Call Next Patient',
                icon: Icons.campaign_rounded,
                height: 52,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CallNextPatientScreen(
                        authService: authService,
                        queueSessionId: effectiveSessionId,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              PrimaryButton(
                label: 'View Completed Patients Queue',
                icon: Icons.check_circle_outline_rounded,
                type: ButtonType.secondary,
                height: 52,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientQueueListScreen(
                        authService: authService,
                        queueSessionId: effectiveSessionId,
                        initialTabIndex: 2,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
