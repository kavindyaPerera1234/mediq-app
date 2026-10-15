import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/queue_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/loading_widget.dart';
import 'consultation_complete_screen.dart';
import 'hold_and_resume_screen.dart';
import 'skip_patient_confirmation_screen.dart';

class CalledPatientStateScreen extends StatefulWidget {
  final AuthService authService;
  final String queueEntryId;

  const CalledPatientStateScreen({
    super.key,
    required this.authService,
    required this.queueEntryId,
  });

  @override
  State<CalledPatientStateScreen> createState() => _CalledPatientStateScreenState();
}

class _CalledPatientStateScreenState extends State<CalledPatientStateScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final QueueService _queueService = QueueService();
  bool _isLoading = false;

  Future<void> _handleCompleteConsultation(QueueEntry entry) async {
    setState(() {
      _isLoading = true;
    });

    final staffUserId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final result = await _queueService.completeConsultation(
      queueEntryId: entry.queueEntryId,
      appointmentId: entry.appointmentId,
      patientId: entry.patientId,
      doctorId: staffUserId,
      notes: 'General OPD Routine Consultation Completed.',
      staffUserId: staffUserId,
    );

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConsultationCompleteScreen(
            authService: widget.authService,
            tokenNumber: entry.tokenNumber,
            patientName: entry.patientName ?? 'Nimali Wijesekera',
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

    final staffUserId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final result = await _queueService.holdPatient(
      queueEntryId: entry.queueEntryId,
      staffUserId: staffUserId,
    );

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HoldAndResumeScreen(
            authService: widget.authService,
            queueSessionId: entry.queueSessionId,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleSkip(QueueEntry entry) async {
    final skipped = await showDialog<bool>(
      context: context,
      builder: (context) => SkipPatientConfirmationScreen(
        authService: widget.authService,
        queueEntryId: entry.queueEntryId,
        tokenNumber: entry.tokenNumber,
        patientName: entry.patientName ?? 'Patient ${entry.tokenNumber}',
      ),
    );
    if (skipped == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Called'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<QueueEntry?>(
        future: _firestoreService.getQueueEntry(widget.queueEntryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const LoadingWidget(message: 'Loading Called Patient Details...');
          }

          final entry = snapshot.data ??
              QueueEntry(
                queueEntryId: widget.queueEntryId,
                queueSessionId: AppConstants.defaultQueueSessionId(),
                appointmentId: 'APT-019',
                patientId: 'pat-019',
                tokenNumber: 'A-019',
                tokenCode: 'A-019',
                status: 'called',
                patientName: 'Nimali Wijesekera',
              );

          final calledTimeStr = entry.calledAt != null
              ? DateFormat('hh:mm a').format(entry.calledAt!)
              : DateFormat('hh:mm a').format(DateTime.now());

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Called Hero Banner
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.volume_up_rounded,
                          size: 48,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'TOKEN CALLED & ACTIVE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.tokenNumber,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Called at $calledTimeStr',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const StatusBadge(status: 'called', isLarge: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Patient Card Info
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
                            'CURRENT CONSULTATION PATIENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primaryLight,
                                child: const Icon(Icons.person, color: AppColors.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.patientName ?? 'Nimali Wijesekera',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'General Medicine OPD Consultation',
                                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  PrimaryButton(
                    label: 'Complete Consultation',
                    icon: Icons.check_circle_rounded,
                    height: 52,
                    onPressed: _isLoading ? null : () => _handleCompleteConsultation(entry),
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
                    label: 'Skip / No Show',
                    icon: Icons.skip_next_rounded,
                    type: ButtonType.destructive,
                    onPressed: _isLoading ? null : () => _handleSkip(entry),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
