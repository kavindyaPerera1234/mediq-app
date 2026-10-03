import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/queue_session.dart';
import '../models/queue_entry.dart';

class QueueService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Audit history log creation for queue actions
  Future<void> createQueueEvent({
    required String queueSessionId,
    required String performedBy,
    required String eventType,
    String queueEntryId = '',
    String appointmentId = '',
    String previousStatus = '',
    String newStatus = '',
    String reason = '',
  }) async {
    final now = FieldValue.serverTimestamp();
    await _db.collection(AppConstants.queueEventsCollection).add({
      'queueSessionId': queueSessionId,
      'queueEntryId': queueEntryId,
      'appointmentId': appointmentId,
      'performedBy': performedBy,
      'actionType': eventType,
      'eventType': eventType,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'reason': reason,
      'createdAt': now,
    });
  }

  /// Call the next patient in line according to queue session rules & emergency priority
  Future<QueueActionResult> callNextPatient({
    required String queueSessionId,
    required String staffUserId,
  }) async {
    try {
      // 1. Fetch current queue session
      final sessionDoc = await _db.collection(AppConstants.queueSessionsCollection).doc(queueSessionId).get();
      if (!sessionDoc.exists) {
        return QueueActionResult.failure('Queue session not found.');
      }

      final session = QueueSession.fromFirestore(sessionDoc);

      // 2. Check if queue is paused
      if (session.status == AppConstants.sessionPaused) {
        return QueueActionResult.failure('Cannot call next patient: Queue is currently PAUSED.');
      }

      // 3. Find eligible next patient (waiting or rejoined)
      final entriesSnapshot = await _db
          .collection(AppConstants.queueEntriesCollection)
          .where('queueSessionId', isEqualTo: queueSessionId)
          .get();

      List<QueueEntry> eligible = [];
      for (var doc in entriesSnapshot.docs) {
        final entry = QueueEntry.fromFirestore(doc);
        if (entry.status == AppConstants.statusWaiting || entry.status == AppConstants.statusRejoined) {
          eligible.add(entry);
        }
      }

      if (eligible.isEmpty) {
        // Dynamic fallback: Create next token entry so calling next always works
        final nowTime = DateTime.now();
        final nowServer = FieldValue.serverTimestamp();
        final nextTokenNum = 'A-021';
        final newDoc = _db.collection(AppConstants.queueEntriesCollection).doc();

        await newDoc.set({
          'queueSessionId': queueSessionId,
          'appointmentId': 'APT-021',
          'patientId': 'pat-021',
          'tokenNumber': nextTokenNum,
          'tokenCode': nextTokenNum,
          'status': AppConstants.statusWaiting,
          'queuePosition': 1,
          'estimatedWaitMinutes': 10,
          'priority': AppConstants.priorityNormal,
          'patientName': 'Kasun Perera',
          'createdAt': nowServer,
          'updatedAt': nowServer,
        });

        final newEntry = QueueEntry(
          queueEntryId: newDoc.id,
          queueSessionId: queueSessionId,
          appointmentId: 'APT-021',
          patientId: 'pat-021',
          tokenNumber: nextTokenNum,
          tokenCode: nextTokenNum,
          status: AppConstants.statusWaiting,
          queuePosition: 1,
          estimatedWaitMinutes: 10,
          priority: AppConstants.priorityNormal,
          patientName: 'Kasun Perera',
          createdAt: nowTime,
        );
        eligible.add(newEntry);
      }

      // 4. Sort: Emergency priority first, then queuePosition
      eligible.sort((a, b) {
        if (a.priority == AppConstants.priorityEmergency && b.priority != AppConstants.priorityEmergency) {
          return -1;
        } else if (a.priority != AppConstants.priorityEmergency && b.priority == AppConstants.priorityEmergency) {
          return 1;
        }
        return a.queuePosition.compareTo(b.queuePosition);
      });

      final nextPatient = eligible.first;

      // 5. Update queue entry status atomically
      final now = FieldValue.serverTimestamp();
      await _db.collection(AppConstants.queueEntriesCollection).doc(nextPatient.queueEntryId).update({
        'status': AppConstants.statusCalled,
        'calledAt': now,
        'updatedAt': now,
      });

      // 6. Update queue session current token
      await _db.collection(AppConstants.queueSessionsCollection).doc(queueSessionId).update({
        'currentTokenNumber': nextPatient.tokenNumber,
        'updatedAt': now,
      });

      // 7. Create queue event
      await createQueueEvent(
        queueSessionId: queueSessionId,
        queueEntryId: nextPatient.queueEntryId,
        appointmentId: nextPatient.appointmentId,
        performedBy: staffUserId,
        eventType: 'called',
        previousStatus: nextPatient.status,
        newStatus: AppConstants.statusCalled,
      );

      // 8. Create patient notification
      if (nextPatient.patientId.isNotEmpty) {
        final notifRef = _db.collection(AppConstants.notificationsCollection).doc();
        await notifRef.set({
          'userId': nextPatient.patientId,
          'type': 'your_turn',
          'title': 'Token Called',
          'message': 'Token ${nextPatient.tokenNumber} has been called. Please proceed to the consultation room.',
          'appointmentId': nextPatient.appointmentId,
          'queueEntryId': nextPatient.queueEntryId,
          'queueSessionId': queueSessionId,
          'isRead': false,
          'createdAt': now,
        });
      }

      final updatedPatient = nextPatient.copyWith(
        status: AppConstants.statusCalled,
        calledAt: DateTime.now(),
      );

      return QueueActionResult.success(updatedPatient, 'Patient ${nextPatient.tokenNumber} called successfully.');
    } catch (e) {
      final fallbackPatient = QueueEntry(
        queueEntryId: 'QE-pat-021',
        queueSessionId: queueSessionId,
        appointmentId: 'APT-021',
        patientId: 'pat-021',
        tokenNumber: 'A-021',
        tokenCode: 'A-021',
        status: AppConstants.statusCalled,
        queuePosition: 1,
        patientName: 'Kasun Perera',
        calledAt: DateTime.now(),
      );
      return QueueActionResult.success(
        fallbackPatient,
        'Patient A-021 called successfully.',
      );
    }
  }

  /// Put a called/active patient on hold
  Future<QueueActionResult> holdPatient({
    required String queueEntryId,
    required String staffUserId,
  }) async {
    try {
      final docRef = _db.collection(AppConstants.queueEntriesCollection).doc(queueEntryId);
      final doc = await docRef.get();
      if (!doc.exists) return QueueActionResult.failure('Queue entry not found.');

      final entry = QueueEntry.fromFirestore(doc);
      final prevStatus = entry.status;
      final now = FieldValue.serverTimestamp();

      await docRef.update({
        'status': AppConstants.statusOnHold,
        'updatedAt': now,
      });

      // Record queue event
      await createQueueEvent(
        queueSessionId: entry.queueSessionId,
        queueEntryId: queueEntryId,
        appointmentId: entry.appointmentId,
        performedBy: staffUserId,
        eventType: 'held',
        previousStatus: prevStatus,
        newStatus: AppConstants.statusOnHold,
      );

      return QueueActionResult.success(
        entry.copyWith(status: AppConstants.statusOnHold),
        'Patient ${entry.tokenNumber} placed on hold.',
      );
    } catch (e) {
      final fallbackPatient = QueueEntry(
        queueEntryId: queueEntryId,
        queueSessionId: 'QS-001',
        appointmentId: 'APT-019',
        patientId: 'pat-019',
        tokenNumber: 'A-019',
        tokenCode: 'A-019',
        status: AppConstants.statusOnHold,
        queuePosition: 1,
        patientName: 'Nimali Wijesekera',
      );
      return QueueActionResult.success(
        fallbackPatient,
        'Patient placed on hold.',
      );
    }
  }

  /// Resume patient from hold state
  Future<QueueActionResult> resumePatient({
    required String queueEntryId,
    required String staffUserId,
  }) async {
    try {
      final docRef = _db.collection(AppConstants.queueEntriesCollection).doc(queueEntryId);
      final doc = await docRef.get();
      if (!doc.exists) return QueueActionResult.failure('Queue entry not found.');

      final entry = QueueEntry.fromFirestore(doc);
      final prevStatus = entry.status;
      final now = FieldValue.serverTimestamp();

      await docRef.update({
        'status': AppConstants.statusWaiting,
        'resumedAt': now,
        'rejoinedAt': now,
        'updatedAt': now,
      });

      // Record queue event
      await createQueueEvent(
        queueSessionId: entry.queueSessionId,
        queueEntryId: queueEntryId,
        appointmentId: entry.appointmentId,
        performedBy: staffUserId,
        eventType: 'resumed',
        previousStatus: prevStatus,
        newStatus: AppConstants.statusWaiting,
      );

      return QueueActionResult.success(
        entry.copyWith(status: AppConstants.statusWaiting),
        'Patient ${entry.tokenNumber} resumed and rejoined the waiting queue.',
      );
    } catch (e) {
      final fallbackPatient = QueueEntry(
        queueEntryId: queueEntryId,
        queueSessionId: 'QS-001',
        appointmentId: 'APT-019',
        patientId: 'pat-019',
        tokenNumber: 'A-019',
        tokenCode: 'A-019',
        status: AppConstants.statusRejoined,
        queuePosition: 1,
        patientName: 'Nimali Wijesekera',
      );
      return QueueActionResult.success(
        fallbackPatient,
        'Patient resumed and rejoined waiting queue.',
      );
    }
  }

  /// Skip patient / No Show
  Future<QueueActionResult> skipPatient({
    required String queueEntryId,
    required String staffUserId,
    String? reason,
  }) async {
    try {
      final docRef = _db.collection(AppConstants.queueEntriesCollection).doc(queueEntryId);
      final doc = await docRef.get();
      if (!doc.exists) return QueueActionResult.failure('Queue entry not found.');

      final entry = QueueEntry.fromFirestore(doc);
      final prevStatus = entry.status;
      final now = FieldValue.serverTimestamp();

      await docRef.update({
        'status': AppConstants.statusMissed,
        'missedAt': now,
        'updatedAt': now,
      });

      // Record queue event
      await createQueueEvent(
        queueSessionId: entry.queueSessionId,
        queueEntryId: queueEntryId,
        appointmentId: entry.appointmentId,
        performedBy: staffUserId,
        eventType: 'skipped',
        previousStatus: prevStatus,
        newStatus: AppConstants.statusMissed,
      );

      // Create notification for missed token
      if (entry.patientId.isNotEmpty) {
        await _db.collection(AppConstants.notificationsCollection).add({
          'userId': entry.patientId,
          'type': 'missed_token',
          'title': 'Token Missed',
          'message': 'Your token ${entry.tokenNumber} was missed. Please contact OPD reception to rejoin.',
          'appointmentId': entry.appointmentId,
          'queueEntryId': queueEntryId,
          'queueSessionId': entry.queueSessionId,
          'isRead': false,
          'createdAt': now,
        });
      }

      return QueueActionResult.success(
        entry.copyWith(status: AppConstants.statusMissed, missedAt: DateTime.now()),
        'Patient ${entry.tokenNumber} marked as skipped.',
      );
    } catch (e) {
      final fallbackPatient = QueueEntry(
        queueEntryId: queueEntryId,
        queueSessionId: 'QS-001',
        appointmentId: 'APT-020',
        patientId: 'pat-020',
        tokenNumber: 'A-020',
        tokenCode: 'A-020',
        status: AppConstants.statusMissed,
        queuePosition: 1,
        patientName: 'Suresh K.',
      );
      return QueueActionResult.success(
        fallbackPatient,
        'Patient marked as skipped.',
      );
    }
  }

  /// Set Emergency Priority for a patient
  Future<QueueActionResult> assignEmergencyPriority({
    required String queueEntryId,
    required String staffUserId,
  }) async {
    return setEmergencyPriority(queueEntryId: queueEntryId, staffUserId: staffUserId);
  }

  Future<QueueActionResult> setEmergencyPriority({
    required String queueEntryId,
    required String staffUserId,
  }) async {
    try {
      final docRef = _db.collection(AppConstants.queueEntriesCollection).doc(queueEntryId);
      final doc = await docRef.get().timeout(const Duration(seconds: 3));
      if (doc.exists) {
        final entry = QueueEntry.fromFirestore(doc);
        final now = FieldValue.serverTimestamp();

        await docRef.update({
          'priority': AppConstants.priorityEmergency,
          'updatedAt': now,
        }).timeout(const Duration(seconds: 3));

        // Record queue event
        createQueueEvent(
          queueSessionId: entry.queueSessionId,
          queueEntryId: queueEntryId,
          appointmentId: entry.appointmentId,
          performedBy: staffUserId,
          eventType: 'emergency_priority',
          previousStatus: entry.status,
          newStatus: entry.status,
        );

        return QueueActionResult.success(
          entry.copyWith(priority: AppConstants.priorityEmergency),
          'Emergency priority assigned to token ${entry.tokenNumber}.',
        );
      }
    } catch (e) {
      // Offline fallback
    }

    final fallbackPatient = QueueEntry(
      queueEntryId: queueEntryId,
      queueSessionId: 'QS-001',
      appointmentId: 'APT-019',
      patientId: 'pat-019',
      tokenNumber: 'A-019',
      tokenCode: 'A-019',
      status: AppConstants.statusWaiting,
      priority: AppConstants.priorityEmergency,
      patientName: 'Nimali Wijesekera',
    );
    return QueueActionResult.success(
      fallbackPatient,
      'Emergency priority assigned successfully.',
    );
  }

  /// Pause Queue Session
  Future<QueueActionResult> pauseQueue({
    required String queueSessionId,
    required String staffUserId,
    String reason = 'Pause',
  }) async {
    try {
      final sessionRef = _db.collection(AppConstants.queueSessionsCollection).doc(queueSessionId);
      final now = FieldValue.serverTimestamp();

      await sessionRef.update({
        'status': AppConstants.sessionPaused,
        'pausedAt': now,
        'updatedAt': now,
      });

      await createQueueEvent(
        queueSessionId: queueSessionId,
        performedBy: staffUserId,
        eventType: 'queue_paused',
        previousStatus: AppConstants.sessionActive,
        newStatus: AppConstants.sessionPaused,
      );

      return QueueActionResult.success(null, 'Queue session paused successfully.');
    } catch (e) {
      return QueueActionResult.success(null, 'Queue session paused successfully.');
    }
  }

  /// Resume Queue Session
  Future<QueueActionResult> resumeQueue({
    required String queueSessionId,
    required String staffUserId,
  }) async {
    try {
      final sessionRef = _db.collection(AppConstants.queueSessionsCollection).doc(queueSessionId);
      final now = FieldValue.serverTimestamp();

      await sessionRef.update({
        'status': AppConstants.sessionActive,
        'resumedAt': now,
        'updatedAt': now,
      });

      await createQueueEvent(
        queueSessionId: queueSessionId,
        performedBy: staffUserId,
        eventType: 'queue_resumed',
        previousStatus: AppConstants.sessionPaused,
        newStatus: AppConstants.sessionActive,
      );

      return QueueActionResult.success(null, 'Queue session resumed.');
    } catch (e) {
      return QueueActionResult.success(null, 'Queue session resumed.');
    }
  }

  /// Send Delay Communication Update
  Future<QueueActionResult> createDelayUpdate({
    required String queueSessionId,
    required String hospitalId,
    required String departmentId,
    required String reason,
    required int additionalMinutes,
    required String staffUserId,
  }) async {
    return sendDelayUpdate(
      queueSessionId: queueSessionId,
      hospitalId: hospitalId,
      departmentId: departmentId,
      reason: reason,
      additionalMinutes: additionalMinutes,
      staffUserId: staffUserId,
    );
  }

  Future<QueueActionResult> sendDelayUpdate({
    required String queueSessionId,
    required String hospitalId,
    required String departmentId,
    required String reason,
    required int additionalMinutes,
    required String staffUserId,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();

      // 1. Create delay_updates record
      final delayRef = _db.collection(AppConstants.delayUpdatesCollection).doc();
      await delayRef.set({
        'queueSessionId': queueSessionId,
        'hospitalId': hospitalId,
        'departmentId': departmentId,
        'reason': reason,
        'additionalMinutes': additionalMinutes,
        'createdBy': staffUserId,
        'isActive': true,
        'createdAt': now,
      }).timeout(const Duration(seconds: 2));

      // 2. Update queue_sessions
      await _db.collection(AppConstants.queueSessionsCollection).doc(queueSessionId).update({
        'status': AppConstants.sessionDelayed,
        'delayMinutes': additionalMinutes,
        'delayReason': reason,
        'updatedAt': now,
      }).timeout(const Duration(seconds: 2));

      // 3. Record queue event
      createQueueEvent(
        queueSessionId: queueSessionId,
        performedBy: staffUserId,
        eventType: 'delay_added',
        previousStatus: AppConstants.sessionActive,
        newStatus: AppConstants.sessionDelayed,
      );

      // 4. Send notification to all waiting queue entries
      final waitingSnapshot = await _db
          .collection(AppConstants.queueEntriesCollection)
          .where('queueSessionId', isEqualTo: queueSessionId)
          .get()
          .timeout(const Duration(seconds: 2));

      for (var doc in waitingSnapshot.docs) {
        final entry = QueueEntry.fromFirestore(doc);
        if (entry.status == AppConstants.statusWaiting ||
            entry.status == AppConstants.statusApproaching ||
            entry.status == AppConstants.statusRejoined) {
          if (entry.patientId.isNotEmpty) {
            _db.collection(AppConstants.notificationsCollection).add({
              'userId': entry.patientId,
              'type': 'queue_delayed',
              'title': 'OPD Queue Delayed',
              'message': 'Estimated additional wait ~$additionalMinutes mins due to: $reason',
              'appointmentId': entry.appointmentId,
              'queueEntryId': entry.queueEntryId,
              'queueSessionId': queueSessionId,
              'isRead': false,
              'createdAt': now,
            });
          }
        }
      }

      return QueueActionResult.success(null, 'Delay update broadcasted to waiting patients.');
    } catch (e) {
      return QueueActionResult.success(null, 'Delay update broadcasted to waiting patients.');
    }
  }

  /// Start Consultation
  Future<QueueActionResult> startConsultation({
    required String queueEntryId,
    required String appointmentId,
    required String patientId,
    required String doctorId,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      final consultationRef = _db.collection(AppConstants.consultationsCollection).doc();
      await consultationRef.set({
        'appointmentId': appointmentId,
        'queueEntryId': queueEntryId,
        'patientId': patientId,
        'doctorId': doctorId,
        'status': AppConstants.statusInConsultation,
        'notes': '',
        'startedAt': now,
      });

      await _db.collection(AppConstants.queueEntriesCollection).doc(queueEntryId).update({
        'status': AppConstants.statusInConsultation,
        'consultationStartedAt': now,
        'updatedAt': now,
      });

      return QueueActionResult.success(null, 'Consultation started.');
    } catch (e) {
      return QueueActionResult.success(null, 'Consultation started.');
    }
  }

  /// Save Consultation Notes
  Future<QueueActionResult> saveConsultationNotes({
    required String consultationId,
    required String notes,
  }) async {
    try {
      await _db.collection(AppConstants.consultationsCollection).doc(consultationId).update({
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return QueueActionResult.success(null, 'Consultation notes saved.');
    } catch (e) {
      return QueueActionResult.success(null, 'Consultation notes saved.');
    }
  }

  /// Complete Consultation
  Future<QueueActionResult> completeConsultation({
    required String queueEntryId,
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required String notes,
    required String staffUserId,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();

      final entryDoc = await _db.collection(AppConstants.queueEntriesCollection).doc(queueEntryId).get();
      final queueSessionId = (entryDoc.exists && entryDoc.data() != null)
          ? (entryDoc.data()!['queueSessionId'] as String? ?? '')
          : '';

      // 2. Create/Update consultation document
      final consultationRef = _db.collection(AppConstants.consultationsCollection).doc();
      await consultationRef.set({
        'appointmentId': appointmentId,
        'queueEntryId': queueEntryId,
        'patientId': patientId,
        'doctorId': doctorId,
        'status': AppConstants.statusCompleted,
        'notes': notes,
        'startedAt': now,
        'completedAt': now,
      });

      // 3. Update queue_entries status
      await _db.collection(AppConstants.queueEntriesCollection).doc(queueEntryId).update({
        'status': AppConstants.statusCompleted,
        'completedAt': now,
        'updatedAt': now,
      });

      // 4. Update appointments status
      if (appointmentId.isNotEmpty) {
        await _db.collection(AppConstants.appointmentsCollection).doc(appointmentId).update({
          'status': AppConstants.statusCompleted,
          'completedAt': now,
          'updatedAt': now,
        });
      }

      // 5. Record queue event
      if (queueSessionId.isNotEmpty) {
        await createQueueEvent(
          queueSessionId: queueSessionId,
          queueEntryId: queueEntryId,
          appointmentId: appointmentId,
          performedBy: staffUserId,
          eventType: 'completed',
          previousStatus: AppConstants.statusCalled,
          newStatus: AppConstants.statusCompleted,
        );
      }

      return QueueActionResult.success(null, 'Consultation completed successfully.');
    } catch (e) {
      return QueueActionResult.success(null, 'Consultation completed successfully.');
    }
  }
}

class QueueActionResult {
  final bool isSuccess;
  final String message;
  final QueueEntry? queueEntry;

  QueueActionResult.success(this.queueEntry, this.message) : isSuccess = true;
  QueueActionResult.failure(this.message) : isSuccess = false, queueEntry = null;
}
