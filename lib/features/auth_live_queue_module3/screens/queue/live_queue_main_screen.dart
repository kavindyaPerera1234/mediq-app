import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../services/live_queue_service.dart';
import '../../models/queue_entry_model.dart';
import 'queue_journey_map_screen.dart';
import 'queue_timeline_screen.dart';
import 'estimated_waiting_time_screen.dart';
import '../states/queue_delayed_screen.dart';
import '../states/your_turn_fullscreen_screen.dart';
import '../states/rejoin_queue_screen.dart';
import '../states/queue_completed_screen.dart';

class LiveQueueMainScreen extends StatefulWidget {
  const LiveQueueMainScreen({super.key});

  @override
  State<LiveQueueMainScreen> createState() => _LiveQueueMainScreenState();
}

class _LiveQueueMainScreenState extends State<LiveQueueMainScreen> {
  final LiveQueueService _queueService = LiveQueueService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _queueService,
      builder: (context, _) {
        final session = _queueService.session;
        final myEntry = _queueService.myEntry;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emergency_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.hospitalName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${session.departmentName} • ${session.roomNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh Queue Data',
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Live Queue refreshed with latest clinic data!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Delay Banner (if active)
                  if (session.isDelayed) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QueueDelayedScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OPD Queue Delayed (+${session.delayMinutes} mins)',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF92400E),
                                    ),
                                  ),
                                  Text(
                                    session.delayReason ?? 'Emergency case admitted to doctor room.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB45309)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // HERO SECTION 1: Now Serving Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'NOW SERVING AT ${session.roomNumber.toUpperCase()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'LIVE',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Big Serving Number
                        Text(
                          session.currentTokenServing,
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Doctor in consultation: ${session.doctorName}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // HERO SECTION 2: YOUR TOKEN (High contrast, clearly separate from now serving!)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0056B3), Color(0xFF003E82)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR TOKEN NUMBER',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withOpacity(0.85),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  myEntry.patientName,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                myEntry.status.name.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            myEntry.tokenCode,
                            style: GoogleFonts.inter(
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white24, thickness: 1),
                        const SizedBox(height: 10),
                        // 2 key metrics: People Ahead & Estimated Wait
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Patients Ahead of You',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${myEntry.peopleAhead} Patients',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 36, color: Colors.white24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimated Wait Time',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '~${myEntry.estimatedWaitMinutes} Minutes',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFFDE047), // Soft bright yellow for quick attention
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SUB-FLOW NAV CARDS (Journey Map, Timeline, Estimated Wait Details)
                  Text(
                    'Queue Journey & Breakdown',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildNavCard(
                    icon: Icons.map_rounded,
                    title: 'Queue Journey Map',
                    subtitle: 'Visual step-by-step roadmap from Hospital Gate to OPD Room',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QueueJourneyMapScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildNavCard(
                    icon: Icons.timeline_rounded,
                    title: 'Live Queue Timeline',
                    subtitle: 'Real-time chronological events & "You are here" marker',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QueueTimelineScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildNavCard(
                    icon: Icons.timer_outlined,
                    title: 'Estimated Waiting Time Breakdown',
                    subtitle: 'Doctor pace calculation, delay factors, and arrival advice',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EstimatedWaitingTimeScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // DEMO CONTROLLER TOOLBAR (For live evaluation / testing all Module 3 states)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.developer_mode_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Test Live Queue States (Demo Bar)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStateButton(
                              label: 'Waiting',
                              color: AppColors.primary,
                              onPressed: () => _queueService.setQueueStatus(PatientQueueStatus.waiting),
                            ),
                            _buildStateButton(
                              label: 'Trigger Delay',
                              color: const Color(0xFFD97706),
                              onPressed: () {
                                _queueService.toggleDelay(!session.isDelayed);
                                if (!session.isDelayed) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const QueueDelayedScreen()),
                                  );
                                }
                              },
                            ),
                            _buildStateButton(
                              label: 'Your Turn! 🔔',
                              color: AppColors.success,
                              onPressed: () {
                                _queueService.setQueueStatus(PatientQueueStatus.called);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const YourTurnFullscreenScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildStateButton(
                              label: 'Missed Turn',
                              color: AppColors.error,
                              onPressed: () {
                                _queueService.setQueueStatus(PatientQueueStatus.missed);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RejoinQueueScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildStateButton(
                              label: 'Completed',
                              color: const Color(0xFF475569),
                              onPressed: () {
                                _queueService.setQueueStatus(PatientQueueStatus.completed);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const QueueCompletedScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildStateButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}
