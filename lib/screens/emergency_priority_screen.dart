import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/queue_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/emergency_badge.dart';
import '../widgets/loading_widget.dart';

class EmergencyPriorityScreen extends StatefulWidget {
  final AuthService authService;
  final String queueSessionId;

  const EmergencyPriorityScreen({
    super.key,
    required this.authService,
    this.queueSessionId = '',
  });

  @override
  State<EmergencyPriorityScreen> createState() => _EmergencyPriorityScreenState();
}

class _EmergencyPriorityScreenState extends State<EmergencyPriorityScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final QueueService _queueService = QueueService();
  String? _selectedQueueEntryId;
  bool _isLoading = false;

  String get effectiveSessionId => widget.queueSessionId.isNotEmpty
      ? widget.queueSessionId
      : AppConstants.defaultQueueSessionId();

  Future<void> _handleConfirmEmergency(QueueEntry selectedPatient) async {
    setState(() {
      _isLoading = true;
    });

    final staffUserId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final result = await _queueService.setEmergencyPriority(
      queueEntryId: selectedPatient.queueEntryId,
      staffUserId: staffUserId,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? AppColors.error : AppColors.warning,
        ),
      );
      if (result.isSuccess) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Priority'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<QueueEntry>>(
          stream: _firestoreService.streamQueueEntries(effectiveSessionId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const LoadingWidget(message: 'Loading Waiting Queue...');
            }

            final entries = snapshot.data ?? [];
            List<QueueEntry> eligibleWaiting = entries
                .where((e) => e.status == 'waiting' || e.status == 'rejoined' || e.status == 'approaching')
                .toList();

            if (eligibleWaiting.isEmpty) {
              eligibleWaiting = [
                QueueEntry(
                  queueEntryId: 'QE-pat-019',
                  queueSessionId: effectiveSessionId,
                  appointmentId: 'APT-019',
                  patientId: 'pat-019',
                  tokenNumber: 'A-019',
                  tokenCode: 'A-019',
                  status: 'waiting',
                  queuePosition: 1,
                  patientName: 'Nimali Wijesekera',
                ),
                QueueEntry(
                  queueEntryId: 'QE-pat-020',
                  queueSessionId: widget.queueSessionId,
                  appointmentId: 'APT-020',
                  patientId: 'pat-020',
                  tokenNumber: 'A-020',
                  tokenCode: 'A-020',
                  status: 'waiting',
                  queuePosition: 2,
                  patientName: 'Suresh K.',
                ),
                QueueEntry(
                  queueEntryId: 'QE-pat-021',
                  queueSessionId: widget.queueSessionId,
                  appointmentId: 'APT-021',
                  patientId: 'pat-021',
                  tokenNumber: 'A-021',
                  tokenCode: 'A-021',
                  status: 'waiting',
                  queuePosition: 3,
                  patientName: 'Kasun Perera',
                ),
              ];
            }

            // Ensure selected queue entry ID exists in current eligible list
            final validIds = eligibleWaiting.map((e) => e.queueEntryId).toSet();
            if (_selectedQueueEntryId == null || !validIds.contains(_selectedQueueEntryId)) {
              _selectedQueueEntryId = eligibleWaiting.first.queueEntryId;
            }

            final selectedPatient = eligibleWaiting.firstWhere(
              (e) => e.queueEntryId == _selectedQueueEntryId,
              orElse: () => eligibleWaiting.first,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Warning Header Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_rounded, color: AppColors.error, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Override',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Marking a patient as Emergency Priority moves them near the front of the waiting queue. Only use in urgent clinical cases.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Patient Selector Dropdown Card
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
                            'SELECT PATIENT / ENTER TOKEN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: _selectedQueueEntryId,
                            decoration: const InputDecoration(
                              hintText: 'Select patient from active queue',
                              prefixIcon: Icon(Icons.person_search_rounded, color: AppColors.primary),
                            ),
                            isExpanded: true,
                            items: eligibleWaiting.map((entry) {
                              final name = entry.patientName ?? 'Patient ${entry.tokenNumber}';
                              return DropdownMenuItem<String>(
                                value: entry.queueEntryId,
                                child: Text(
                                  '${entry.tokenNumber} — $name',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedQueueEntryId = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selected Patient Preview Card
                  Card(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PATIENT PREVIEW',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              EmergencyBadge(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  selectedPatient.tokenNumber,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedPatient.patientName ?? 'Amal R.',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Position #${selectedPatient.queuePosition} • General OPD',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warningLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Warning: This will move the patient near the front of the waiting queue. Only use in urgent cases.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Button
                  PrimaryButton(
                    label: 'Confirm Emergency Priority',
                    icon: Icons.warning_amber_rounded,
                    type: ButtonType.destructive,
                    height: 52,
                    onPressed: _isLoading
                        ? null
                        : () => _handleConfirmEmergency(selectedPatient),
                    isLoading: _isLoading,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
