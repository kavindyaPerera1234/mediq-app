import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/live_queue_service.dart';

class QueueDelayedScreen extends StatelessWidget {
  const QueueDelayedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueService = LiveQueueService();
    final session = queueService.session;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB), // Soft warm amber background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF78350F), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Delay Warning Icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF59E0B), width: 3),
                  ),
                  child: const Center(
                    child: Icon(Icons.alarm_on_rounded, color: Color(0xFFD97706), size: 48),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'OPD Clinic Delayed',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF78350F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dr. H. M. Perera\'s clinic in Room 04 has announced a temporary queue delay.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF92400E),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Delay Information Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'ESTIMATED ADDITIONAL DELAY',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB45309),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+${session.delayMinutes > 0 ? session.delayMinutes : 25} Mins',
                      style: GoogleFonts.inter(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFFEF3C7)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Reason given by Clinic Staff:\n"${session.delayReason ?? 'Emergency trauma patient admitted for immediate examination.'}"',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF78350F),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Comfort Advice Card for waiting patients
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What should you do now?',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Your token position is preserved. You do not need to stand in the queue.\n'
                      '• Feel free to sit in Waiting Lounge B or visit the Hospital Cafeteria.\n'
                      '• MediQ will alert you automatically when regular consultations resume.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF92400E),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Return Button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                ),
                child: Text(
                  'Understood, Back to Live Queue',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
