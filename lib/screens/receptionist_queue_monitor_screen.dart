import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/queue_session.dart';
import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/emergency_badge.dart';
import 'patient_queue_list_screen.dart';
import '../features/token_lifecycle_notification_module2/screens/qr_scanner_screen.dart';

class ReceptionistQueueMonitorScreen extends StatefulWidget {
  final AuthService authService;

  const ReceptionistQueueMonitorScreen({
    super.key,
    required this.authService,
  });

  @override
  State<ReceptionistQueueMonitorScreen> createState() => _ReceptionistQueueMonitorScreenState();
}

class _ReceptionistQueueMonitorScreenState extends State<ReceptionistQueueMonitorScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final staffUser = widget.authService.currentUserModel;
    final staffProfile = widget.authService.currentStaffProfile;
    final userRole = staffProfile?.role ?? staffUser?.role ?? 'receptionist';
    final hId = staffProfile?.hospitalId ?? 'nhsl';
    final dId = staffProfile?.departmentId ?? 'gen_med';
    final genMedSessionId = AppConstants.defaultQueueSessionId(
      hId.isNotEmpty ? hId : 'nhsl',
      dId.isNotEmpty ? dId : 'gen_med',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Queue Monitor — Reception'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Patient QR Code',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QrScannerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reception Role Banner Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC084FC)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7E22CE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.desktop_windows_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OPD RECEPTION DESK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7E22CE),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            staffUser?.fullName ?? 'Receptionist Silva',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7E22CE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        userRole.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick QR Scanner / Digital Check-in Action Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B21A8), Color(0xFF7E22CE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7E22CE).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan Patient Token / Check-in',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Verify patient booking & check in via QR code pass',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'LIVE OPD CLINIC QUEUES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Department 1: General Medicine OPD (Real-time Firestore)
              StreamBuilder<QueueSession?>(
                stream: _firestoreService.streamQueueSession(genMedSessionId),
                builder: (context, sessionSnapshot) {
                  final session = sessionSnapshot.data ??
                      QueueSession(
                        queueSessionId: genMedSessionId,
                        hospitalId: hId.isNotEmpty ? hId : 'nhsl',
                        departmentId: dId.isNotEmpty ? dId : 'gen_med',
                        date: DateTime.now().toString().split(' ')[0],
                        status: 'active',
                        currentTokenNumber: 'A-019',
                      );

                  return StreamBuilder<List<QueueEntry>>(
                    stream: _firestoreService.streamQueueEntries(genMedSessionId),
                    builder: (context, entriesSnapshot) {
                      final entries = entriesSnapshot.data ?? [];
                      final waitingCount = entries
                          .where((e) => e.status == 'waiting' || e.status == 'rejoined' || e.status == 'approaching')
                          .length;
                      final hasEmergency = entries.any((e) => e.priority == 'emergency' && e.status != 'completed');

                      return _buildDepartmentMonitorCard(
                        department: 'General Medicine OPD',
                        doctorName: 'Dr. Silva',
                        status: session.status,
                        currentToken: session.currentTokenNumber,
                        waitingCount: waitingCount,
                        hasEmergency: hasEmergency,
                        delayMessage: session.delayMinutes > 0 ? session.delayReason : null,
                        queueSessionId: genMedSessionId,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 14),

              // Department 2: Pediatrics OPD (Demo Card)
              _buildDepartmentMonitorCard(
                department: 'Pediatrics OPD',
                doctorName: 'Dr. Fernando',
                status: 'active',
                currentToken: 'P-008',
                waitingCount: 5,
                hasEmergency: false,
              ),
              const SizedBox(height: 14),

              // Department 3: Orthopedics OPD (Demo Card with Delay)
              _buildDepartmentMonitorCard(
                department: 'Orthopedics OPD',
                doctorName: 'Dr. Jayas',
                status: 'delayed',
                currentToken: 'O-012',
                waitingCount: 8,
                hasEmergency: true,
                delayMessage: 'Surgeon in emergency operation (~20 mins delay)',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentMonitorCard({
    required String department,
    required String doctorName,
    required String status,
    required String currentToken,
    required int waitingCount,
    bool hasEmergency = false,
    String? delayMessage,
    String queueSessionId = '',
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientQueueListScreen(
                authService: widget.authService,
                queueSessionId: queueSessionId.isNotEmpty
                    ? queueSessionId
                    : AppConstants.defaultQueueSessionId(),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Doctor: $doctorName',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            const Divider(height: 20),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT TOKEN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentToken,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WAITING COUNT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$waitingCount Patients',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (hasEmergency) ...[
              const SizedBox(height: 12),
              const EmergencyBadge(compact: true),
            ],

            if (delayMessage != null && delayMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        delayMessage,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}
