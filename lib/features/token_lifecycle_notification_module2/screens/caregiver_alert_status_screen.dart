import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../services/queue_alert_trigger_service.dart';
import '../services/notification_service.dart';

class CaregiverAlertStatusScreen extends StatefulWidget {
  final String appointmentId;

  const CaregiverAlertStatusScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<CaregiverAlertStatusScreen> createState() =>
      _CaregiverAlertStatusScreenState();
}

class _CaregiverAlertStatusScreenState
    extends State<CaregiverAlertStatusScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final NotificationService _notificationService =
      NotificationService();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _appointment;
  Map<String, dynamic>? _caregiver;
  Map<String, dynamic>? _queueEntry;

  int _patientsAhead = 0;

  bool _notificationProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // --------------------------------------------------------
      // 1. LOAD APPOINTMENT
      // --------------------------------------------------------

      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      if (!appointmentDoc.exists ||
          appointmentDoc.data() == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _error = 'Appointment not found.';
        });

        return;
      }

      final appointmentData =
          appointmentDoc.data()!;

      // --------------------------------------------------------
      // 2. GET CAREGIVER
      // --------------------------------------------------------

      Map<String, dynamic>? caregiver;

      final assistedQueue =
          appointmentData['assistedQueue'];

      if (assistedQueue is Map) {
        final caregiverValue =
            assistedQueue['caregiver'];

        if (caregiverValue is Map) {
          caregiver =
              Map<String, dynamic>.from(
            caregiverValue,
          );
        }
      }

      // --------------------------------------------------------
      // 3. GET QUEUE ENTRY
      // --------------------------------------------------------

      Map<String, dynamic>? queueEntry;

      final queueQuery = await _firestore
          .collection('queue_entries')
          .where(
            'appointmentId',
            isEqualTo: widget.appointmentId,
          )
          .limit(10)
          .get();

      if (queueQuery.docs.isNotEmpty) {
        // Prefer an active queue entry.
        for (final doc in queueQuery.docs) {
          final data = doc.data();

          final status =
              data['status']
                  ?.toString()
                  .toLowerCase();

          if (status == 'waiting' ||
              status == 'confirmed' ||
              status == 'called' ||
              status == 'serving' ||
              status == 'active') {
            queueEntry = {
              ...data,
              'id': doc.id,
            };

            break;
          }
        }

        queueEntry ??= {
          ...queueQuery.docs.first.data(),
          'id': queueQuery.docs.first.id,
        };
      }

      // --------------------------------------------------------
      // 4. CALCULATE PATIENTS AHEAD
      // --------------------------------------------------------

      int patientsAhead = 0;

      if (queueEntry != null) {
        patientsAhead =
            await _calculatePatientsAhead(
          currentEntry: queueEntry,
        );
      }

      if (!mounted) return;

      setState(() {
        _appointment = appointmentData;
        _caregiver = caregiver;
        _queueEntry = queueEntry;
        _patientsAhead = patientsAhead;
        _isLoading = false;
      });

      // --------------------------------------------------------
      // 5. PROCESS QUEUE ALERT
      // --------------------------------------------------------

      await _processQueueAlert(
        appointmentData: appointmentData,
        caregiver: caregiver,
        queueEntry: queueEntry,
        patientsAhead: patientsAhead,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Unable to load alert status.';
      });
    }
  }

  // ============================================================
  // PROCESS QUEUE ALERT
  // ============================================================

  Future<void> _processQueueAlert({
    required Map<String, dynamic> appointmentData,
    required Map<String, dynamic>? caregiver,
    required Map<String, dynamic>? queueEntry,
    required int patientsAhead,
  }) async {
    if (_notificationProcessing) {
      return;
    }

    if (queueEntry == null ||
        caregiver == null) {
      return;
    }

    final patientUid =
        appointmentData['patientId']?.toString();

    final caregiverUid =
        caregiver['uid']?.toString();

    final appointmentId =
        widget.appointmentId;

    final queueEntryId =
        queueEntry['id']?.toString();

    final queueSessionId =
        queueEntry['queueSessionId']?.toString();

    if (patientUid == null ||
        patientUid.isEmpty ||
        caregiverUid == null ||
        caregiverUid.isEmpty ||
        queueEntryId == null ||
        queueEntryId.isEmpty ||
        queueSessionId == null ||
        queueSessionId.isEmpty) {
      return;
    }

    final alertStage =
        QueueAlertTriggerService.getAlertStage(
      patientsAhead: patientsAhead,
    );

    // No notification when the patient is still far away.
    if (alertStage == 'WAITING') {
      return;
    }

    _notificationProcessing = true;

    try {
      await _createAlertsIfNeeded(
        stage: alertStage,
        patientUid: patientUid,
        caregiverUid: caregiverUid,
        appointmentId: appointmentId,
        queueEntryId: queueEntryId,
        queueSessionId: queueSessionId,
        patientsAhead: patientsAhead,
      );
    } finally {
      _notificationProcessing = false;
    }
  }

  // ============================================================
  // CHECK + CREATE NOTIFICATIONS
  // ============================================================

  Future<void> _createAlertsIfNeeded({
    required String stage,
    required String patientUid,
    required String caregiverUid,
    required String appointmentId,
    required String queueEntryId,
    required String queueSessionId,
    required int patientsAhead,
  }) async {
    final notificationTypes =
        stage == 'APPROACHING'
            ? [
                'queue_approaching',
                'caregiver_queue_approaching',
              ]
            : [
                'your_turn',
                'caregiver_your_turn',
              ];

    // ----------------------------------------------------------
    // Check whether this alert was already created.
    // This prevents duplicate notifications every time
    // the screen is opened/refreshed.
    // ----------------------------------------------------------

    final existingQuery = await _firestore
        .collection('notifications')
        .where(
          'appointmentId',
          isEqualTo: appointmentId,
        )
        .where(
          'type',
          whereIn: notificationTypes,
        )
        .limit(20)
        .get();

    bool patientAlreadyNotified = false;
    bool caregiverAlreadyNotified = false;

    for (final doc in existingQuery.docs) {
      final data = doc.data();

      final userId =
          data['userId']?.toString();

      if (userId == patientUid) {
        patientAlreadyNotified = true;
      }

      if (userId == caregiverUid) {
        caregiverAlreadyNotified = true;
      }
    }

    // ----------------------------------------------------------
    // APPROACHING
    // ----------------------------------------------------------

    if (stage == 'APPROACHING') {
      if (!patientAlreadyNotified) {
        await _notificationService
            .createApproachingNotification(
          userId: patientUid,
          appointmentId: appointmentId,
          queueEntryId: queueEntryId,
          queueSessionId: queueSessionId,
          patientsAhead: patientsAhead,
          isCaregiver: false,
        );
      }

      if (!caregiverAlreadyNotified) {
        await _notificationService
            .createApproachingNotification(
          userId: caregiverUid,
          appointmentId: appointmentId,
          queueEntryId: queueEntryId,
          queueSessionId: queueSessionId,
          patientsAhead: patientsAhead,
          isCaregiver: true,
        );
      }

      return;
    }

    // ----------------------------------------------------------
    // YOUR TURN
    // ----------------------------------------------------------

    if (stage == 'YOUR_TURN') {
      if (!patientAlreadyNotified) {
        await _notificationService
            .createYourTurnNotification(
          userId: patientUid,
          appointmentId: appointmentId,
          queueEntryId: queueEntryId,
          queueSessionId: queueSessionId,
          isCaregiver: false,
        );
      }

      if (!caregiverAlreadyNotified) {
        await _notificationService
            .createYourTurnNotification(
          userId: caregiverUid,
          appointmentId: appointmentId,
          queueEntryId: queueEntryId,
          queueSessionId: queueSessionId,
          isCaregiver: true,
        );
      }
    }
  }

  // ============================================================
  // CALCULATE PATIENTS AHEAD
  // ============================================================

  Future<int> _calculatePatientsAhead({
    required Map<String, dynamic> currentEntry,
  }) async {
    final queuePositionValue =
        currentEntry['queuePosition'];

    int? currentPosition;

    if (queuePositionValue is num) {
      currentPosition =
          queuePositionValue.toInt();
    } else if (queuePositionValue != null) {
      currentPosition =
          int.tryParse(
        queuePositionValue.toString(),
      );
    }

    if (currentPosition == null) {
      return 0;
    }

    // Get queue session.
    final queueSessionId =
        currentEntry['queueSessionId']
            ?.toString();

    QuerySnapshot<Map<String, dynamic>>
        snapshot;

    if (queueSessionId != null &&
        queueSessionId.isNotEmpty) {
      snapshot = await _firestore
          .collection('queue_entries')
          .where(
            'queueSessionId',
            isEqualTo: queueSessionId,
          )
          .get();
    } else {
      // Fallback: use appointmentId.
      snapshot = await _firestore
          .collection('queue_entries')
          .where(
            'appointmentId',
            isEqualTo: widget.appointmentId,
          )
          .get();
    }

    int count = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      // Don't count the current patient.
      final currentAppointmentId =
          currentEntry['appointmentId']
              ?.toString();

      final otherAppointmentId =
          data['appointmentId']
              ?.toString();

      if (currentAppointmentId != null &&
          currentAppointmentId ==
              otherAppointmentId) {
        continue;
      }

      // Only count active queue entries.
      final status =
          data['status']
              ?.toString()
              .toLowerCase();

      final isActive =
          status == 'waiting' ||
          status == 'confirmed' ||
          status == 'called' ||
          status == 'serving' ||
          status == 'active';

      if (!isActive) {
        continue;
      }

      final positionValue =
          data['queuePosition'];

      int? position;

      if (positionValue is num) {
        position =
            positionValue.toInt();
      } else if (positionValue != null) {
        position =
            int.tryParse(
          positionValue.toString(),
        );
      }

      if (position != null &&
          position < currentPosition) {
        count++;
      }
    }

    return count;
  }

  // ============================================================
  // SAFE VALUE
  // ============================================================

  String _getValue(
    Map<String, dynamic>? data,
    List<String> keys, {
    String fallback = 'Not available',
  }) {
    if (data == null) {
      return fallback;
    }

    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  // ============================================================
  // TOKEN
  // ============================================================

  String _getToken() {
    return _getValue(
      _queueEntry,
      [
        'tokenCode',
        'tokenNumber',
      ],
      fallback: _getValue(
        _appointment,
        [
          'token',
          'tokenNumber',
          'tokenCode',
        ],
        fallback: 'Not assigned',
      ),
    );
  }

  // ============================================================
  // WAIT TIME
  // ============================================================

  String _getEstimatedWait() {
    final value =
        _queueEntry?['estimatedWaitMinutes'];

    if (value is num) {
      return '${value.toInt()} min';
    }

    if (value != null) {
      return '$value min';
    }

    return 'Not available';
  }

  // ============================================================
  // QUEUE STATUS
  // ============================================================

  String _getQueueStatus() {
    return _getValue(
      _queueEntry,
      ['status'],
      fallback: 'Not available',
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // NOTIFICATION ROW
  // ============================================================

  Widget _notificationRow({
    required String title,
    required String text,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration:
              const BoxDecoration(
            color: Color(0xFFE8F4FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 17,
            color: Color(0xFF0879E1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style:
                    const TextStyle(
                  fontSize: 10,
                  color:
                      AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ALERT STAGE COLOR
  // ============================================================

  Color _stageColor(
    String stage,
  ) {
    switch (stage) {
      case 'YOUR_TURN':
        return Colors.red;

      case 'APPROACHING':
        return AppColors.primary;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color:
                AppColors.textPrimary,
            size: 19,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Caregiver Alert Status',
          style: TextStyle(
            color:
                AppColors.textPrimary,
            fontSize: 17,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 45,
                color:
                    Colors.redAccent,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed:
                    _loadData,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor:
                      Colors.white,
                ),
                child:
                    const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_caregiver == null) {
      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(24),
          child: Text(
            'No caregiver has been added to this appointment.',
            textAlign:
                TextAlign.center,
          ),
        ),
      );
    }

    // ==========================================================
    // DATA
    // ==========================================================

    final department =
        _getValue(
      _appointment,
      [
        'departmentName',
        'department',
      ],
      fallback:
          'General Medicine OPD',
    );

    final doctor =
        _getValue(
      _appointment,
      [
        'doctorName',
        'doctor',
      ],
      fallback: 'Doctor',
    );

    final caregiverName =
        _getValue(
      _caregiver,
      [
        'name',
        'fullName',
      ],
      fallback: 'Caregiver',
    );

    final caregiverPhone =
        _getValue(
      _caregiver,
      ['phone'],
      fallback: 'Not available',
    );

    final relationship =
        _getValue(
      _caregiver,
      ['relationship'],
      fallback: 'Caregiver',
    );

    final token = _getToken();

    final estimatedWait =
        _getEstimatedWait();

    final queueStatus =
        _getQueueStatus();

    // ==========================================================
    // ALERT STAGE
    // ==========================================================

    final alertStage =
        QueueAlertTriggerService
            .getAlertStage(
      patientsAhead:
          _patientsAhead,
    );

    final stageMessage =
        QueueAlertTriggerService
            .getStageMessage(
      patientsAhead:
          _patientsAhead,
    );

    final stageColor =
        _stageColor(
      alertStage,
    );

    // Notification display text.
    final notificationStatus =
        alertStage == 'WAITING'
            ? 'Waiting for queue to approach'
            : alertStage == 'APPROACHING'
                ? 'Notification created for patient and caregiver'
                : 'Urgent notification created for patient and caregiver';

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child:
          SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            // ==================================================
            // TOKEN HEADER
            // ==================================================

            _card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Token $token',
                              style:
                                  const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .green
                                    .shade50,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child:
                                  const Text(
                                'Active',
                                style:
                                    TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          '$department - $doctor',
                          style:
                              const TextStyle(
                            fontSize: 11,
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // ALERT STAGE
            // ==================================================

            _card(
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration:
                    BoxDecoration(
                  color: stageColor
                      .withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      alertStage ==
                              'YOUR_TURN'
                          ? Icons
                              .notifications_active
                          : Icons
                              .notifications_none,
                      color: stageColor,
                      size: 23,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            alertStage.replaceAll(
                              '_',
                              ' ',
                            ),
                            style:
                                TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  stageColor,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            stageMessage,
                            style:
                                const TextStyle(
                              fontSize: 11,
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // NOTIFICATION STATUS
            // ==================================================

            _card(
              child: Column(
                children: [
                  _notificationRow(
                    title:
                        'Patient notification',
                    text:
                        notificationStatus,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  _notificationRow(
                    title:
                        'Caregiver notification',
                    text:
                        notificationStatus,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // QUEUE STATUS
            // ==================================================

            _card(
              child: Column(
                children: [
                  _queueInfoRow(
                    icon: Icons
                        .confirmation_number_outlined,
                    label:
                        'Your token:',
                    value: token,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _queueInfoRow(
                    icon:
                        Icons.people_outline,
                    label:
                        'Patients ahead:',
                    value:
                        _patientsAhead
                            .toString(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _queueInfoRow(
                    icon:
                        Icons.access_time,
                    label:
                        'Estimated wait:',
                    value:
                        estimatedWait,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _queueInfoRow(
                    icon:
                        Icons.info_outline,
                    label:
                        'Queue status:',
                    value:
                        queueStatus,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // CAREGIVER
            // ==================================================

            const Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                'Caregiver',
                style:
                    TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                  color: AppColors
                      .textPrimary,
                ),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            _card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          caregiverName,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                            color: AppColors
                                .textPrimary,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          '$caregiverPhone ($relationship)',
                          style:
                              const TextStyle(
                            fontSize: 10,
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _actionButton(
                    icon: Icons.phone,
                    onTap: () {
                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Call $caregiverPhone',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _actionButton(
                    icon: Icons
                        .message_outlined,
                    onTap: () {
                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Message $caregiverPhone',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // INFORMATION
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.green.shade50,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: const Text(
                'Caregiver alerts will be sent according to the selected notification preferences when the queue reaches the relevant stage.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUEUE INFO ROW
  // ============================================================

  Widget _queueInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color:
              AppColors.textSecondary,
        ),
        const SizedBox(
          width: 9,
        ),
        Text(
          label,
          style:
              const TextStyle(
            fontSize: 12,
            color:
                AppColors.textSecondary,
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        Expanded(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration:
              BoxDecoration(
            color: AppColors.primary
                .withValues(
              alpha: 0.08,
            ),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color:
                AppColors.primary,
          ),
        ),
      ),
    );
  }
}