import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/queue_service.dart';
import '../widgets/queue_card.dart';
import '../widgets/loading_widget.dart';
import 'patient_queue_detail_screen.dart';

class HoldAndResumeScreen extends StatefulWidget {
  final AuthService authService;
  final String queueSessionId;

  const HoldAndResumeScreen({
    super.key,
    required this.authService,
    this.queueSessionId = 'QS-001',
  });

  @override
  State<HoldAndResumeScreen> createState() => _HoldAndResumeScreenState();
}

class _HoldAndResumeScreenState extends State<HoldAndResumeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final QueueService _queueService = QueueService();
  String? _resumingId;

  Future<void> _handleResume(QueueEntry entry) async {
    setState(() {
      _resumingId = entry.queueEntryId;
    });

    final staffUserId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final result = await _queueService.resumePatient(
      queueEntryId: entry.queueEntryId,
      staffUserId: staffUserId,
    );

    setState(() {
      _resumingId = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patients on Hold'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<QueueEntry>>(
          stream: _firestoreService.streamQueueEntries(widget.queueSessionId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const LoadingWidget(message: 'Loading Patients on Hold...');
            }

            final entries = snapshot.data ?? [];
            final onHoldList = entries.where((e) => e.status == 'on_hold').toList();

            if (onHoldList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.pause_circle_outline_rounded,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Patients Currently On Hold',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Patients marked as "On Hold" during OPD consultation calls will appear here for easy resuming.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: onHoldList.length,
              itemBuilder: (context, index) {
                final entry = onHoldList[index];
                final isResuming = _resumingId == entry.queueEntryId;

                return QueueCard(
                  entry: entry,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientQueueDetailScreen(
                          authService: widget.authService,
                          queueEntryId: entry.queueEntryId,
                        ),
                      ),
                    );
                  },
                  primaryActionLabel: isResuming ? 'Resuming...' : 'Resume',
                  onPrimaryAction: isResuming ? null : () => _handleResume(entry),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
