import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../widgets/primary_button.dart';

class StaffDelayCommunicationScreen extends StatefulWidget {
  final AuthService authService;
  final String queueSessionId;

  const StaffDelayCommunicationScreen({
    super.key,
    required this.authService,
    this.queueSessionId = 'QS-001',
  });

  @override
  State<StaffDelayCommunicationScreen> createState() => _StaffDelayCommunicationScreenState();
}

class _StaffDelayCommunicationScreenState extends State<StaffDelayCommunicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController(text: 'Doctor attending emergency ward round');
  final _minutesController = TextEditingController(text: '30');
  final QueueService _queueService = QueueService();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _handleSendDelayNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final staffProfile = widget.authService.currentStaffProfile;
    final staffUserId = widget.authService.currentUserModel?.uid ?? 'staff-uid';
    final hospitalId = staffProfile?.hospitalId ?? 'HOSP-001';
    final departmentId = staffProfile?.departmentId ?? 'DEPT-001';
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 30;

    final result = await _queueService.sendDelayUpdate(
      queueSessionId: widget.queueSessionId,
      hospitalId: hospitalId,
      departmentId: departmentId,
      reason: _reasonController.text.trim(),
      additionalMinutes: minutes,
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
    final minutesVal = _minutesController.text.trim();
    final delayText = minutesVal.isNotEmpty ? '$minutesVal minutes' : '30 minutes';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Send Delay Update'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Department Banner
                Card(
                  color: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current OPD Department',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'General Medicine OPD',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Form Inputs Card
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
                          'Delay Reason',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Doctor attending emergency surgery',
                            prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.primary),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a reason for the delay';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 18),

                        const Text(
                          'Estimated Additional Wait Time (Minutes)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _minutesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '30',
                            prefixIcon: Icon(Icons.timer_outlined, color: AppColors.primary),
                            suffixText: 'mins',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter estimated wait time';
                            }
                            if (int.tryParse(value.trim()) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Delay Message Preview Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Current delay message: Estimated additional wait ~$delayText',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Buttons
                PrimaryButton(
                  label: 'Send Notification to All Patients',
                  icon: Icons.send_rounded,
                  height: 52,
                  onPressed: _isLoading ? null : _handleSendDelayNotification,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 12),

                PrimaryButton(
                  label: 'Cancel',
                  type: ButtonType.outline,
                  height: 48,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
