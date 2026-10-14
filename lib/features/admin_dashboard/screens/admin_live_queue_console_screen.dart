import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_strings.dart';

class AdminLiveQueueConsoleScreen extends StatefulWidget {
  const AdminLiveQueueConsoleScreen({super.key});

  @override
  State<AdminLiveQueueConsoleScreen> createState() => _AdminLiveQueueConsoleScreenState();
}

class _AdminLiveQueueConsoleScreenState extends State<AdminLiveQueueConsoleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all'; // 'all', 'active', 'delayed', 'paused'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Live Queue Master Control',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Fast-Track Emergency Token',
            onPressed: () => _showAddEmergencyDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Overview Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('all', 'All Queues'),
                        const SizedBox(width: 8),
                        _buildFilterPill('active', 'Active'),
                        const SizedBox(width: 8),
                        _buildFilterPill('delayed', 'Delayed'),
                        const SizedBox(width: 8),
                        _buildFilterPill('paused', 'Paused'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Real-time Queue Sessions Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection(AppConstants.queueSessionsCollection).snapshots(),
              builder: (context, sessionSnap) {
                if (sessionSnap.hasError) {
                  return Center(
                    child: Text(
                      'Error loading queue sessions: ${sessionSnap.error}',
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                  );
                }

                if (!sessionSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = sessionSnap.data!.docs;

                // Filter docs
                if (_filterStatus != 'all') {
                  docs = docs.where((d) => (d.data()['status'] ?? 'active') == _filterStatus).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.queue_outlined, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No queue sessions match filter "$_filterStatus"',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return _buildQueueSessionCard(doc.id, doc.data());
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _filterStatus == key;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E293B) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQueueSessionCard(String sessionId, Map<String, dynamic> data) {
    final deptId = data['departmentId'] ?? 'OPD';
    final deptName = _formatDeptName(deptId);
    final status = (data['status'] ?? 'active').toString().toLowerCase();
    final currentToken = data['currentToken'] ?? data['currentTokenNumber'] ?? 'A-001';
    final lastIssued = data['lastIssuedToken'] ?? data['lastIssuedTokenNumber'] ?? currentToken;
    final delayMinutes = data['delayMinutes'] ?? 0;
    final delayReason = data['delayReason'];
    final isDelayed = status == 'delayed' || (delayMinutes is num && delayMinutes > 0);
    final isPaused = status == 'paused';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDelayed
              ? Colors.amber.shade400
              : isPaused
                  ? Colors.blueGrey.shade300
                  : AppColors.border,
          width: isDelayed ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Department, Room, Status Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deptName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Session: $sessionId',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _statusBadge(status, isDelayed),
              ],
            ),
          ),

          // If Delayed: Prominent Warning Banner with Clear Action
          if (isDelayed)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '+$delayMinutes min Delay Broadcasted',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        if (delayReason != null && delayReason.toString().isNotEmpty)
                          Text(
                            delayReason.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.amber.shade800,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _clearDelay(sessionId),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(50, 30),
                    ),
                    child: Text(
                      'Clear Delay',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 16, color: AppColors.border),

          // Metrics: Current Serving, Waiting Patients, Last Issued
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // Now Serving
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOW SERVING',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentToken.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Live Waiting Count Stream
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection(AppConstants.queueEntriesCollection)
                        .where('queueSessionId', isEqualTo: sessionId)
                        .snapshots(),
                    builder: (context, entrySnap) {
                      final waitingCount = entrySnap.hasData
                          ? entrySnap.data!.docs.where((d) => d.data()['status'] == 'waiting').length
                          : 0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WAITING PATIENTS',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$waitingCount in Line',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Latest: $lastIssued',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Admin Action Controls Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // 1. Advance / Call Next Patient
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: Text(
                      'Call Next',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _advanceToken(sessionId, currentToken.toString()),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Broadcast Delay Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade800,
                      side: BorderSide(color: Colors.amber.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: Text(
                      'Delay',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _showBroadcastDelayModal(context, sessionId),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Pause / Resume Toggle
                IconButton(
                  tooltip: isPaused ? 'Resume OPD Queue' : 'Pause OPD Queue',
                  icon: Icon(
                    isPaused ? Icons.play_circle_fill_rounded : Icons.pause_circle_filled_rounded,
                    color: isPaused ? AppColors.statusGreen : AppColors.textSecondary,
                    size: 28,
                  ),
                  onPressed: () => _togglePauseQueue(sessionId, isPaused),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, bool isDelayed) {
    Color bg;
    Color fg;
    String label;

    if (isDelayed) {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
      label = 'DELAYED';
    } else if (status == 'paused') {
      bg = Colors.blueGrey.shade100;
      fg = Colors.blueGrey.shade900;
      label = 'PAUSED';
    } else if (status == 'active') {
      bg = AppColors.statusGreen.withValues(alpha: 0.15);
      fg = AppColors.statusGreen;
      label = 'ACTIVE';
    } else {
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade700;
      label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  String _formatDeptName(String deptId) {
    switch (deptId.toLowerCase()) {
      case 'gen_med':
      case 'general_medicine':
        return 'General Medicine OPD';
      case 'pediatrics':
        return 'Pediatrics Clinic';
      case 'orthopedics':
        return 'Orthopedics Clinic';
      case 'ent':
        return 'ENT Specialty OPD';
      case 'cardiology':
        return 'Cardiology Clinic';
      default:
        return '${deptId.toUpperCase()} Clinic';
    }
  }

  // ── Operations ─────────────────────────────────────────────────────────────

  Future<void> _advanceToken(String sessionId, String currentToken) async {
    try {
      // Find next waiting token in queue_entries for this session
      final waitingQuery = await _firestore
          .collection(AppConstants.queueEntriesCollection)
          .where('queueSessionId', isEqualTo: sessionId)
          .where('status', isEqualTo: 'waiting')
          .get();

      String nextToken = '';
      final batch = _firestore.batch();

      if (waitingQuery.docs.isNotEmpty) {
        final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(waitingQuery.docs)
          ..sort((a, b) {
            final posA = (a.data()['queuePosition'] as num?)?.toInt() ?? 999;
            final posB = (b.data()['queuePosition'] as num?)?.toInt() ?? 999;
            return posA.compareTo(posB);
          });
        final nextDoc = sortedDocs.first;
        nextToken = nextDoc.data()['tokenCode'] ?? 'A-001';

        // Update entry to 'called'
        batch.update(nextDoc.reference, {
          'status': 'called',
          'calledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Fallback: Increment token number directly
        final match = RegExp(r'([A-Za-z]+)-?(\d+)').firstMatch(currentToken);
        if (match != null) {
          final prefix = match.group(1);
          final num = int.tryParse(match.group(2) ?? '0') ?? 0;
          nextToken = '$prefix-${(num + 1).toString().padLeft(3, '0')}';
        } else {
          nextToken = 'A-001';
        }
      }

      // Update queue session current token
      final sessionRef = _firestore.collection(AppConstants.queueSessionsCollection).doc(sessionId);
      batch.update(sessionRef, {
        'currentToken': nextToken,
        'currentTokenNumber': nextToken,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log event to queue_events
      final eventRef = _firestore.collection(AppConstants.queueEventsCollection).doc();
      batch.set(eventRef, {
        'queueSessionId': sessionId,
        'eventType': 'called',
        'tokenCode': nextToken,
        'performedBy': 'admin_master_control',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Called Next Patient: Token $nextToken'),
          backgroundColor: AppColors.statusGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to call next token: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _togglePauseQueue(String sessionId, bool currentlyPaused) async {
    try {
      final newStatus = currentlyPaused ? 'active' : 'paused';
      await _firestore.collection(AppConstants.queueSessionsCollection).doc(sessionId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyPaused ? 'OPD Queue Resumed.' : 'OPD Queue Paused.'),
          backgroundColor: currentlyPaused ? AppColors.statusGreen : Colors.blueGrey,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle queue pause: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _clearDelay(String sessionId) async {
    try {
      await _firestore.collection(AppConstants.queueSessionsCollection).doc(sessionId).update({
        'status': 'active',
        'delayMinutes': 0,
        'delayReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OPD Delay cleared. Clinic returned to standard schedule.'),
          backgroundColor: AppColors.statusGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear delay: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showBroadcastDelayModal(BuildContext context, String sessionId) {
    int selectedMinutes = 30;
    String selectedReason = 'Doctor attending emergency ward';
    final customReasonController = TextEditingController();

    final reasons = [
      'Doctor attending emergency ward',
      'Doctor delayed in hospital rounds',
      'Complex patient examination taking longer',
      'Temporary diagnostic equipment delay',
      'Other (Specify below)',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Broadcast OPD Delay Alert',
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    Text(
                      'Delay Duration:',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [15, 30, 45, 60].map((mins) {
                        final isSel = selectedMinutes == mins;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedMinutes = mins),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel ? Colors.amber.shade800 : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? Colors.amber.shade800 : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+$mins min',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Delay Reason:',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    ...reasons.map((r) {
                      return RadioListTile<String>(
                        value: r,
                        groupValue: selectedReason,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(r, style: GoogleFonts.inter(fontSize: 13)),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedReason = val);
                          }
                        },
                      );
                    }),

                    if (selectedReason.startsWith('Other')) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customReasonController,
                        decoration: InputDecoration(
                          hintText: 'Enter specific delay explanation...',
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.broadcast_on_personal_rounded),
                        label: Text(
                          'Broadcast Delay to All Patients',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final finalReason = selectedReason.startsWith('Other') &&
                                  customReasonController.text.trim().isNotEmpty
                              ? customReasonController.text.trim()
                              : selectedReason;

                          Navigator.pop(modalCtx);

                          try {
                            final batch = _firestore.batch();
                            final sessionRef =
                                _firestore.collection(AppConstants.queueSessionsCollection).doc(sessionId);

                            batch.update(sessionRef, {
                              'status': 'delayed',
                              'delayMinutes': selectedMinutes,
                              'delayReason': finalReason,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            // Log in delay_updates
                            final delayRef = _firestore.collection(AppConstants.delayUpdatesCollection).doc();
                            batch.set(delayRef, {
                              'queueSessionId': sessionId,
                              'additionalMinutes': selectedMinutes,
                              'reason': finalReason,
                              'createdBy': 'admin_master_control',
                              'isActive': true,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            await batch.commit();

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('+$selectedMinutes min delay broadcasted across OPD queue.'),
                                backgroundColor: Colors.amber.shade900,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to broadcast delay: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddEmergencyDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final nicCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                'Fast-Track Emergency Token',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Immediately issues a top-priority token for critical OPD arrivals.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Patient Full Name',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nicCtrl,
                decoration: InputDecoration(
                  hintText: 'Patient NIC / ID',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(S.btnCancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final nic = nicCtrl.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(dialogCtx);

                try {
                  final now = DateTime.now();
                  final emgTokenCode = 'EMG-${now.minute}${now.second}';
                  final sessionId = AppConstants.defaultQueueSessionId();

                  await _firestore.collection(AppConstants.queueEntriesCollection).add({
                    'patientName': name,
                    'patientNic': nic,
                    'tokenCode': emgTokenCode,
                    'queueSessionId': sessionId,
                    'status': 'waiting',
                    'priority': 'emergency',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Emergency Token $emgTokenCode issued for $name!'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to issue emergency token: $e'), backgroundColor: AppColors.error),
                  );
                }
              },
              child: const Text('Issue Emergency Token', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
