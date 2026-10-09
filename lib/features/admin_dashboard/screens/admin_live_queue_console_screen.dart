import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/queue_session.dart';
import '../../../models/queue_entry.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/queue_service.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/emergency_badge.dart';
import '../../../widgets/loading_widget.dart';

class AdminLiveQueueConsoleScreen extends StatefulWidget {
  final AuthService authService;

  const AdminLiveQueueConsoleScreen({
    super.key,
    required this.authService,
  });

  @override
  State<AdminLiveQueueConsoleScreen> createState() => _AdminLiveQueueConsoleScreenState();
}

class _AdminLiveQueueConsoleScreenState extends State<AdminLiveQueueConsoleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final QueueService _queueService = QueueService();
  bool _isLoading = false;

  String get _currentSessionId {
    final profile = widget.authService.currentStaffProfile;
    return AppConstants.defaultQueueSessionId(profile?.hospitalId, profile?.departmentId);
  }

  Future<void> _handleCallSpecific(QueueEntry entry) async {
    setState(() => _isLoading = true);
    final staffId = widget.authService.currentUserModel?.uid ?? 'admin-uid';
    final result = await _queueService.callSpecificPatient(
      queueEntryId: entry.queueEntryId,
      staffUserId: staffId,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleTogglePause(bool isCurrentlyPaused) async {
    setState(() => _isLoading = true);
    final staffId = widget.authService.currentUserModel?.uid ?? 'admin-uid';

    final result = isCurrentlyPaused
        ? await _queueService.resumeQueue(queueSessionId: _currentSessionId, staffUserId: staffId)
        : await _queueService.pauseQueue(queueSessionId: _currentSessionId, staffUserId: staffId, reason: 'Admin Override Pause');

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? AppColors.warning : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Master Live Queue Console'),
      ),
      body: SafeArea(
        child: StreamBuilder<QueueSession?>(
          stream: _firestoreService.streamQueueSession(_currentSessionId),
          builder: (context, sessionSnapshot) {
            final session = sessionSnapshot.data ??
                QueueSession(
                  queueSessionId: _currentSessionId,
                  hospitalId: 'nhsl',
                  departmentId: 'gen_med',
                  date: DateTime.now().toString().split(' ')[0],
                  status: 'active',
                  currentTokenNumber: 'A-019',
                );

            final isPaused = session.status == 'paused';

            return StreamBuilder<List<QueueEntry>>(
              stream: _firestoreService.streamPatientQueue(_currentSessionId),
              builder: (context, entriesSnapshot) {
                if (entriesSnapshot.connectionState == ConnectionState.waiting && !entriesSnapshot.hasData) {
                  return const LoadingWidget(message: 'Loading Live Queue Data...');
                }

                final entries = entriesSnapshot.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Master Queue Banner Card
                      Card(
                        color: isPaused ? AppColors.warningLight : AppColors.primaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isPaused ? AppColors.warning : AppColors.primary),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'OPD LIVE OVERRIDE',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                      const Text(
                                        'General Medicine OPD',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  StatusBadge(status: session.status, isLarge: true),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: PrimaryButton(
                                      label: isPaused ? 'RESUME QUEUE' : 'PAUSE QUEUE',
                                      icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                      type: isPaused ? ButtonType.primary : ButtonType.secondary,
                                      onPressed: _isLoading ? null : () => _handleTogglePause(isPaused),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'REAL-TIME PATIENT QUEUE REGISTRY',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 12),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entries.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: entry.priority == 'emergency' ? AppColors.errorLight : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.tokenNumber,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: entry.priority == 'emergency' ? AppColors.error : AppColors.primary,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(entry.patientName ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (entry.priority == 'emergency') ...[
                                    const SizedBox(width: 8),
                                    const EmergencyBadge(),
                                  ],
                                ],
                              ),
                              subtitle: Text('Status: ${entry.status.toUpperCase()}'),
                              trailing: entry.status == 'waiting' || entry.status == 'on_hold'
                                  ? ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                      onPressed: _isLoading ? null : () => _handleCallSpecific(entry),
                                      child: const Text('Call', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    )
                                  : StatusBadge(status: entry.status),
                            ),
                          );
                        },
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
