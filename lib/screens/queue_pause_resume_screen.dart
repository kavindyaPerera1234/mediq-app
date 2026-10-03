import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/queue_session.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/queue_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/loading_widget.dart';

class QueuePauseResumeScreen extends StatefulWidget {
  final AuthService authService;
  final String queueSessionId;

  const QueuePauseResumeScreen({
    super.key,
    required this.authService,
    this.queueSessionId = 'QS-001',
  });

  @override
  State<QueuePauseResumeScreen> createState() => _QueuePauseResumeScreenState();
}

class _QueuePauseResumeScreenState extends State<QueuePauseResumeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final QueueService _queueService = QueueService();
  String _selectedReason = 'Lunch Break';
  bool _isLoading = false;

  final List<String> _pauseReasons = [
    'Lunch Break',
    'Doctor unavailable',
    'Emergency',
    'Other',
  ];

  Future<void> _handlePauseQueue() async {
    setState(() {
      _isLoading = true;
    });

    final staffUserId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final result = await _queueService.pauseQueue(
      queueSessionId: widget.queueSessionId,
      staffUserId: staffUserId,
      reason: _selectedReason,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? AppColors.warning : AppColors.error,
        ),
      );
      if (result.isSuccess) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleResumeQueue() async {
    setState(() {
      _isLoading = true;
    });

    final staffUserId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final result = await _queueService.resumeQueue(
      queueSessionId: widget.queueSessionId,
      staffUserId: staffUserId,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
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
        title: const Text('Queue Control'),
      ),
      body: SafeArea(
        child: StreamBuilder<QueueSession?>(
          stream: _firestoreService.streamQueueSession(widget.queueSessionId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const LoadingWidget(message: 'Loading Queue Status...');
            }

            final session = snapshot.data ??
                QueueSession(
                  queueSessionId: widget.queueSessionId,
                  hospitalId: 'HOSP-001',
                  departmentId: 'DEPT-001',
                  date: '2026-09-24',
                  status: 'active',
                );

            final isPaused = session.status == 'paused';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Display Card
                  Card(
                    color: isPaused ? AppColors.warningLight : AppColors.successLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isPaused ? AppColors.warning : AppColors.success,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            isPaused ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            size: 48,
                            color: isPaused ? AppColors.warning : AppColors.success,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Queue Status',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPaused ? 'QUEUE PAUSED' : 'QUEUE ACTIVE',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isPaused ? AppColors.warning : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!isPaused) ...[
                    // Pausing Warning Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.warning),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pausing will temporarily stop calling patients until the queue is resumed.',
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

                    // Pause Reasons Card
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
                              'SELECT PAUSE REASON',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: _pauseReasons.map((reason) {
                                return RadioListTile<String>(
                                  title: Text(
                                    reason,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  value: reason,
                                  groupValue: _selectedReason,
                                  activeColor: AppColors.primary,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedReason = val;
                                      });
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    PrimaryButton(
                      label: 'Pause Queue',
                      icon: Icons.pause_rounded,
                      type: ButtonType.destructive,
                      height: 52,
                      onPressed: _isLoading ? null : _handlePauseQueue,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 12),

                    PrimaryButton(
                      label: 'Cancel',
                      type: ButtonType.outline,
                      height: 48,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ] else ...[
                    // Resuming View
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Resume Queue',
                      icon: Icons.play_arrow_rounded,
                      type: ButtonType.primary,
                      height: 54,
                      onPressed: _isLoading ? null : _handleResumeQueue,
                      isLoading: _isLoading,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
