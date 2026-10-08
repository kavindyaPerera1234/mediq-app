import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/queue_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/emergency_badge.dart';
import '../widgets/loading_widget.dart';
import 'called_patient_state_screen.dart';
import 'skip_patient_confirmation_screen.dart';

class PatientQueueDetailScreen extends StatefulWidget {
  final AuthService authService;
  final String queueEntryId;

  const PatientQueueDetailScreen({
    super.key,
    required this.authService,
    required this.queueEntryId,
  });

  @override
  State<PatientQueueDetailScreen> createState() => _PatientQueueDetailScreenState();
}

class _PatientQueueDetailScreenState extends State<PatientQueueDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final QueueService _queueService = QueueService();
  bool _isLoading = false;

  Future<void> _handleCallPatient(QueueEntry entry) async {
    setState(() {
      _isLoading = true;
    });

    final staffId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final result = await _queueService.callNextPatient(
      queueSessionId: entry.queueSessionId,
      staffUserId: staffId,
    );

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CalledPatientStateScreen(
            authService: widget.authService,
            queueEntryId: entry.queueEntryId,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handlePutOnHold(QueueEntry entry) async {
    setState(() {
      _isLoading = true;
    });

    final staffId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final result = await _queueService.holdPatient(
      queueEntryId: entry.queueEntryId,
      staffUserId: staffId,
    );

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.warning),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
      );
    }
  }

  void _handleSkipPatient(QueueEntry entry) {
    showDialog(
      context: context,
      builder: (context) => SkipPatientConfirmationScreen(
        authService: widget.authService,
        queueEntryId: entry.queueEntryId,
        tokenNumber: entry.tokenNumber,
        patientName: entry.patientName ?? 'Patient ${entry.tokenNumber}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Queue Detail'),
        elevation: 0,
      ),
      body: FutureBuilder<QueueEntry?>(
        future: _firestoreService.getQueueEntry(widget.queueEntryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const LoadingWidget(message: 'Loading Patient Queue Details...');
          }

          final entry = snapshot.data;
          if (entry == null) {
            return const Center(
              child: Text('Patient Queue Record Not Found.'),
            );
          }

          final isEmergency = entry.priority == 'emergency';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Token Card
                  Card(
                    color: isEmergency ? AppColors.errorLight : AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isEmergency ? AppColors.error : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                      child: Column(
                        children: [
                          if (isEmergency) ...[
                            const EmergencyBadge(),
                            const SizedBox(height: 12),
                          ],
                          const Text(
                            'CURRENT TOKEN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.tokenNumber,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: isEmergency ? AppColors.error : AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StatusBadge(status: entry.status, isLarge: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Patient Information Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PATIENT INFORMATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.person_rounded,
                            label: 'Patient Name',
                            value: entry.patientName ?? 'Nimali Wijesekera',
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Appointment',
                            value: '8:30 AM — General Medicine',
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            icon: Icons.format_list_numbered_rounded,
                            label: 'Queue Position',
                            value: 'Position #${entry.queuePosition} (Est. ~${entry.estimatedWaitMinutes} mins)',
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            icon: Icons.priority_high_rounded,
                            label: 'Priority Level',
                            value: entry.priority.toUpperCase(),
                            valueColor: isEmergency ? AppColors.error : AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  PrimaryButton(
                    label: 'Call Patient',
                    icon: Icons.campaign_rounded,
                    onPressed: _isLoading ? null : () => _handleCallPatient(entry),
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 12),

                  PrimaryButton(
                    label: 'Put on Hold',
                    icon: Icons.pause_circle_filled_rounded,
                    type: ButtonType.secondary,
                    onPressed: _isLoading ? null : () => _handlePutOnHold(entry),
                  ),
                  const SizedBox(height: 12),

                  PrimaryButton(
                    label: 'Skip Patient',
                    icon: Icons.skip_next_rounded,
                    type: ButtonType.destructive,
                    onPressed: _isLoading ? null : () => _handleSkipPatient(entry),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
