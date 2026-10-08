import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_accessibility.dart';
import '../../services/live_queue_service.dart';
import '../../models/queue_entry_model.dart';
import '../../../patient_appointment_scheduling_module1/screens/hospital_selection_screen.dart';
import 'queue_journey_map_screen.dart';
import 'queue_timeline_screen.dart';
import 'estimated_waiting_time_screen.dart';
import '../states/queue_delayed_screen.dart';
import '../states/your_turn_fullscreen_screen.dart';
import '../states/queue_completed_screen.dart';
import '../states/rejoin_queue_screen.dart';

class LiveQueueMainScreen extends StatefulWidget {
  const LiveQueueMainScreen({super.key});

  @override
  State<LiveQueueMainScreen> createState() => _LiveQueueMainScreenState();
}

class _LiveQueueMainScreenState extends State<LiveQueueMainScreen> {
  final LiveQueueService _queueService = LiveQueueService();
  StreamSubscription<PatientQueueStatus>? _statusSub;

  @override
  void initState() {
    super.initState();
    _statusSub = _queueService.statusChanges.listen((status) {
      if (!mounted) return;
      if (status == PatientQueueStatus.called) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const YourTurnFullscreenScreen()),
        );
      } else if (status == PatientQueueStatus.missed) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RejoinQueueScreen()),
        );
      } else if (status == PatientQueueStatus.completed) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QueueCompletedScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _queueService,
        AppAccessibility.isHighContrastMode,
        AppAccessibility.currentLanguage,
      ]),
      builder: (context, _) {
        final session = _queueService.session;
        final myEntry = _queueService.myEntry;
        final isDark = AppAccessibility.isHighContrastMode.value;

        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            backgroundColor: AppColors.cardSurface,
            elevation: isDark ? 1 : 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF243356) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.emergency_outlined, color: AppColors.accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.hospitalName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.headingText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${session.departmentName} • ${session.roomNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.bodyText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh Queue Data',
                icon: Icon(Icons.refresh_rounded, color: AppColors.accentColor),
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
              PopupMenuButton<String>(
                tooltip: 'Queue Screen Quick Switcher',
                icon: Icon(Icons.more_vert_rounded, color: AppColors.accentColor),
                onSelected: (value) {
                  if (value == 'rejoin') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RejoinQueueScreen()),
                    );
                  } else if (value == 'completed') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QueueCompletedScreen()),
                    );
                  } else if (value == 'timeline') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QueueTimelineScreen()),
                    );
                  } else if (value == 'journey') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QueueJourneyMapScreen()),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rejoin',
                    child: Row(
                      children: [
                        Icon(Icons.replay_circle_filled_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 10),
                        Text('Rejoin Missed Queue Screen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'completed',
                    child: Row(
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                        SizedBox(width: 10),
                        Text('Consultation Completed Screen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'timeline',
                    child: Row(
                      children: [
                        Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Text('Queue Timeline View', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'journey',
                    child: Row(
                      children: [
                        Icon(Icons.map_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Text('Patient Journey Map', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Appointments Switcher (when patient has multiple bookings)
                  if (_queueService.myAppointments.length > 1) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _queueService.myAppointments.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final appt = _queueService.myAppointments[i];
                          final id = (appt['id'] ?? '').toString();
                          final token = (appt['tokenCode'] ?? '—').toString();
                          final dept = (appt['departmentName'] ?? 'Clinic').toString();
                          final status = (appt['status'] ?? 'confirmed').toString().toUpperCase();
                          final isSelected = id == _queueService.currentAppointmentId;

                          return ChoiceChip(
                            label: Text('$token • $dept ($status)'),
                            selected: isSelected,
                            selectedColor: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                            backgroundColor: AppColors.cardSurface,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.headingText,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                                    : AppColors.cardBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            onSelected: (_) => _queueService.selectAppointment(id),
                          );
                        },
                      ),
                    ),
                  ],

                  // Empty State Banner (if no active appointment)
                  if (!_queueService.hasActiveAppointment) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy_rounded, size: 48, color: AppColors.accentColor),
                          const SizedBox(height: 12),
                          Text(
                            'No Active OPD Queue Today',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.headingText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You do not currently have a confirmed appointment for today\'s clinic sessions.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.bodyText),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const HospitalSelectionScreen()),
                              );
                            },
                            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                            label: const Text('Book OPD Appointment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Missed Turn Alert Banner (triggers Rejoin screen directly)
                  if (myEntry.status == PatientQueueStatus.missed) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RejoinQueueScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YOU MISSED YOUR TURN',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your token was called. Tap here to rejoin the queue immediately without rebooking.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.95),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Consultation Completed Banner
                  if (myEntry.status == PatientQueueStatus.completed) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QueueCompletedScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF047857),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF047857).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CONSULTATION COMPLETED',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your OPD visit is complete. Tap to view your consultation summary & token receipt.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.95),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Rejoined Active Queue Banner
                  if (myEntry.rejoinRequested) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF3B82F6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.replay_rounded, color: Color(0xFF1D4ED8), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Queue Rejoin Active',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E40AF),
                                  ),
                                ),
                                Text(
                                  'You have rejoined the queue. You are placed behind the next 2 patients.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Called / Turn Active Banner (triggers fullscreen alert)
                  if (myEntry.status == PatientQueueStatus.called) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const YourTurnFullscreenScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF15803D).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YOUR TURN IS CALLED NOW!',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Please enter ${session.roomNumber} immediately. Tap for alert.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.95),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],

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
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.04),
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
                            Expanded(
                              child: Row(
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
                                  Expanded(
                                    child: Text(
                                      'NOW SERVING AT ${session.roomNumber.toUpperCase()}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: AppColors.bodyText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF14532D) : AppColors.successLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'LIVE',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFF4ADE80) : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Big Serving Number
                        Text(
                          session.currentTokenServing == '—' ? 'Not Started' : session.currentTokenServing,
                          style: GoogleFonts.inter(
                            fontSize: session.currentTokenServing == '—' ? 36 : 48,
                            fontWeight: FontWeight.w900,
                            color: session.currentTokenServing == '—'
                                ? AppColors.bodyText
                                : (isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.currentTokenServing == '—'
                              ? 'Waiting for doctor to call first patient'
                              : 'Doctor in consultation: ${session.doctorName}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.bodyText,
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
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF14244B), Color(0xFF0D1B3E)]
                            : const [Color(0xFF0056B3), Color(0xFF003E82)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: isDark ? Border.all(color: const Color(0xFF38BDF8), width: 1.5) : null,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF38BDF8) : AppColors.primary).withValues(alpha: 0.28),
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
                                    color: Colors.white.withValues(alpha: 0.85),
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
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                                      color: Colors.white.withValues(alpha: 0.8),
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
                                      color: Colors.white.withValues(alpha: 0.8),
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
                      color: AppColors.headingText,
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
    final isDark = AppAccessibility.isHighContrastMode.value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF243356) : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accentColor, size: 24),
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
                      color: AppColors.headingText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
