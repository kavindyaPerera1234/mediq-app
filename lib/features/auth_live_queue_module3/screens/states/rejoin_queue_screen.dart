import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../services/live_queue_service.dart';

class RejoinQueueScreen extends StatefulWidget {
  const RejoinQueueScreen({super.key});

  @override
  State<RejoinQueueScreen> createState() => _RejoinQueueScreenState();
}

class _RejoinQueueScreenState extends State<RejoinQueueScreen> {
  String _selectedReason = 'Using washroom / restroom';
  bool _isSubmitted = false;
  bool _isLoading = false;

  final List<String> _reasons = [
    'Using washroom / restroom',
    'Mobility / Wheelchair delay',
    'Collecting laboratory / blood test reports',
    'Unwell / Resting in cool waiting lobby',
    'Caregiver assisting another family member',
    'Public transport / Morning rush delay',
    'Other personal emergency',
  ];

  Future<void> _handleRejoin() async {
    setState(() => _isLoading = true);
    final success = await LiveQueueService().rejoinQueue(_selectedReason);
    setState(() {
      _isLoading = false;
      _isSubmitted = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    final queueService = LiveQueueService();
    final myEntry = queueService.myEntry;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isSubmitted) ...[
                // Missed turn warning badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.error, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Missed Turn Recovery',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Token ${myEntry.tokenCode} • Room 04',
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Reassurance Card (Milestone 1 requirement: No patient abandoned!)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Don\'t worry, your consultation is not lost!',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Because you were away when Token ${myEntry.tokenCode} was called, the nursing officer moved to the next patient. You can request to re-enter the queue with high priority.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Why did you miss the call? *',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedReason,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                      items: _reasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(
                            reason,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedReason = val);
                      },
                    ),
                  ),
                ),

                const Spacer(),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRejoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Request Immediate Queue Rejoin',
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Success Rejoined Confirmation
                const Spacer(flex: 1),
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.success, width: 3),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Rejoin Request Sent to Staff!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dr. H. M. Perera\'s desk in Room 04 has been notified. You have been placed into the priority buffer (2 patients ahead).',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'NEW EXPECTED WAIT TIME',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '~10 Minutes',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please stay in Waiting Lounge B opposite Room 04.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Return to Live Queue',
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
