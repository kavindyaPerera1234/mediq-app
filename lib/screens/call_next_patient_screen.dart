import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/queue_session.dart';
import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/queue_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/emergency_badge.dart';
import '../widgets/loading_widget.dart';
import 'called_patient_state_screen.dart';

class CallNextPatientScreen extends StatefulWidget {
  final AuthService authService;
  final String queueSessionId;

  const CallNextPatientScreen({
    super.key,
    required this.authService,
    this.queueSessionId = '',
  });

  @override
  State<CallNextPatientScreen> createState() => _CallNextPatientScreenState();
}

class _CallNextPatientScreenState extends State<CallNextPatientScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final QueueService _queueService = QueueService();
  bool _isCalling = false;

  String get effectiveSessionId => widget.queueSessionId.isNotEmpty
      ? widget.queueSessionId
      : AppConstants.defaultQueueSessionId();

  Future<void> _handleCallNext() async {
    setState(() {
      _isCalling = true;
    });

    final staffUserId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final result = await _queueService.callNextPatient(
      queueSessionId: effectiveSessionId,
      staffUserId: staffUserId,
    );

    setState(() {
      _isCalling = false;
    });

    if (result.isSuccess && result.queueEntry != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CalledPatientStateScreen(
            authService: widget.authService,
            queueEntryId: result.queueEntry!.queueEntryId,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Queue Control'),
      ),
      body: SafeArea(
        child: StreamBuilder<QueueSession?>(
          stream: _firestoreService.streamQueueSession(effectiveSessionId),
          builder: (context, sessionSnapshot) {
            final session = sessionSnapshot.data ??
                QueueSession(
                  queueSessionId: effectiveSessionId,
                  hospitalId: 'nhsl',
                  departmentId: 'gen_med',
                  date: DateTime.now().toString().split(' ')[0],
                  currentTokenNumber: '—',
                );

            final isPaused = session.status == 'paused';

            return StreamBuilder<List<QueueEntry>>(
              stream: _firestoreService.streamQueueEntries(effectiveSessionId),
              builder: (context, entriesSnapshot) {
                if (entriesSnapshot.connectionState == ConnectionState.waiting && !entriesSnapshot.hasData) {
                  return const LoadingWidget(message: 'Loading Next Patient Info...');
                }

                final entries = entriesSnapshot.data ?? [];

                // Active called patient
                final calledPatient = entries.firstWhere(
                  (e) => e.status == 'called' || e.status == 'in_consultation',
                  orElse: () => QueueEntry(
                    queueEntryId: '',
                    queueSessionId: widget.queueSessionId,
                    appointmentId: '',
                    patientId: '',
                    tokenNumber: session.currentTokenNumber,
                    tokenCode: session.currentTokenNumber,
                  ),
                );

                // Last completed patient
                final completedList = entries.where((e) => e.status == 'completed').toList();
                final QueueEntry? lastCompleted = completedList.isNotEmpty ? completedList.last : null;

                // Next eligible patient (waiting/rejoined with emergency priority first)
                final waitingList = entries
                    .where((e) => e.status == 'waiting' || e.status == 'rejoined' || e.status == 'approaching')
                    .toList();

                waitingList.sort((a, b) {
                  if (a.priority == 'emergency' && b.priority != 'emergency') return -1;
                  if (a.priority != 'emergency' && b.priority == 'emergency') return 1;
                  return a.queuePosition.compareTo(b.queuePosition);
                });

                final QueueEntry? nextInLine = waitingList.isNotEmpty ? waitingList.first : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isPaused) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.pause_circle_filled_rounded, color: AppColors.warning, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'QUEUE IS PAUSED. Calling next patient is disabled until queue is resumed.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section 1: Current Active Token Card
                      Card(
                        elevation: 1,
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
                                'CURRENT ACTIVE TOKEN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    calledPatient.tokenNumber.isNotEmpty
                                        ? calledPatient.tokenNumber
                                        : session.currentTokenNumber,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  StatusBadge(
                                    status: calledPatient.status.isNotEmpty ? calledPatient.status : 'active',
                                  ),
                                ],
                              ),
                              if (calledPatient.patientName != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  calledPatient.patientName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (lastCompleted != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'LAST COMPLETED TOKEN',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        '${lastCompleted.tokenNumber} — ${lastCompleted.patientName ?? 'Patient'}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const StatusBadge(status: 'completed'),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Section 2: Next in Line Card
                      Card(
                        color: (nextInLine?.priority == 'emergency')
                            ? AppColors.errorLight
                            : AppColors.primaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: (nextInLine?.priority == 'emergency')
                                ? AppColors.error
                                : AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'NEXT IN LINE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  if (nextInLine?.priority == 'emergency') const EmergencyBadge(compact: true),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                nextInLine?.tokenNumber ?? '—',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: (nextInLine?.priority == 'emergency')
                                      ? AppColors.error
                                      : AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nextInLine != null
                                    ? (nextInLine.patientName ?? 'Patient ${nextInLine.tokenNumber}')
                                    : 'No patients currently waiting',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nextInLine != null
                                    ? 'General Medicine OPD • Position #${nextInLine.queuePosition}'
                                    : 'New bookings will automatically appear here',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Call Next Patient Primary Button
                      PrimaryButton(
                        label: nextInLine == null ? 'NO PATIENTS IN QUEUE' : 'CALL NEXT PATIENT',
                        icon: Icons.campaign_rounded,
                        height: 54,
                        onPressed: (isPaused || _isCalling || nextInLine == null)
                            ? null
                            : _handleCallNext,
                        isLoading: _isCalling,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
