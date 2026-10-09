import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../widgets/primary_button.dart';

class SkipPatientConfirmationScreen extends StatefulWidget {
  final AuthService authService;
  final String queueEntryId;
  final String tokenNumber;
  final String patientName;

  const SkipPatientConfirmationScreen({
    super.key,
    required this.authService,
    required this.queueEntryId,
    required this.tokenNumber,
    required this.patientName,
  });

  @override
  State<SkipPatientConfirmationScreen> createState() => _SkipPatientConfirmationScreenState();
}

class _SkipPatientConfirmationScreenState extends State<SkipPatientConfirmationScreen> {
  final QueueService _queueService = QueueService();
  bool _isLoading = false;

  Future<void> _handleConfirmSkip() async {
    setState(() {
      _isLoading = true;
    });

    final staffUserId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final result = await _queueService.skipPatient(
      queueEntryId: widget.queueEntryId,
      staffUserId: staffUserId,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pop(context); // Close dialog
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.skip_next_rounded, color: AppColors.error, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Skip Patient?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Token & Patient Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.tokenNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'This patient will be marked as skipped in the queue audit history. Continue?',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Confirm Skip',
                    type: ButtonType.destructive,
                    height: 44,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: _isLoading ? null : _handleConfirmSkip,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
