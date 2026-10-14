import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_preference_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // CREATE BASIC NOTIFICATION
  // ============================================================

  Future<String?> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? appointmentId,
    String? queueEntryId,
    String? queueSessionId,
    bool isUrgent = false,
  }) async {
    try {
      if (userId.trim().isEmpty) {
        return null;
      }

      final enabled =
          await NotificationPreferenceService.isEnabled(
        userId: userId,
        type: type,
      );

      if (!enabled) {
        return null;
      }

      final data = <String, dynamic>{
        'userId': userId.trim(),
        'type': type,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (appointmentId != null &&
          appointmentId.trim().isNotEmpty) {
        data['appointmentId'] =
            appointmentId.trim();
      }

      if (queueEntryId != null &&
          queueEntryId.trim().isNotEmpty) {
        data['queueEntryId'] =
            queueEntryId.trim();
      }

      if (queueSessionId != null &&
          queueSessionId.trim().isNotEmpty) {
        data['queueSessionId'] =
            queueSessionId.trim();
      }

      if (isUrgent) {
        data['isUrgent'] = true;
      }

      final document = await _firestore
          .collection('notifications')
          .add(data);

      return document.id;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // APPOINTMENT REMINDER
  // ============================================================

  Future<void> checkAndCreateAppointmentReminder(
    String patientIdentifier,
  ) async {
    try {
      final identifier =
          patientIdentifier.trim();

      if (identifier.isEmpty) {
        return;
      }

      final now = DateTime.now();

      // Reminder should only be created after 6:00 AM.
      if (now.hour < 6) {
        return;
      }

      final appointmentSnapshot =
          await _firestore
              .collection('appointments')
              .get();

      for (final appointmentDoc
          in appointmentSnapshot.docs) {
        final data =
            appointmentDoc.data();

        final patientId =
            (data['patientId'] ?? '')
                .toString()
                .trim();

        final patientNic =
            (data['patientNic'] ?? '')
                .toString()
                .trim();

        final userId =
            (data['userId'] ?? '')
                .toString()
                .trim();

        final belongsToPatient =
            patientId == identifier ||
            patientNic == identifier ||
            userId == identifier;

        if (!belongsToPatient) {
          continue;
        }

        final status =
            (data['status'] ?? '')
                .toString()
                .toLowerCase()
                .trim();

        // Do not create reminders for inactive appointments.
        if (status == 'cancelled' ||
            status == 'completed' ||
            status == 'done' ||
            status == 'missed' ||
            status == 'no_show') {
          continue;
        }

        final appointmentDate =
            _parseAppointmentDate(
          data['appointmentDate'],
        );

        if (appointmentDate == null) {
          continue;
        }

        final isToday =
            appointmentDate.year == now.year &&
            appointmentDate.month == now.month &&
            appointmentDate.day == now.day;

        if (!isToday) {
          continue;
        }

        final notificationUserId =
            (data['userId'] ??
                    data['patientId'] ??
                    identifier)
                .toString()
                .trim();

        final reminderEnabled =
            await NotificationPreferenceService.isEnabled(
          userId: notificationUserId,
          type: 'reminder',
        );

        if (!reminderEnabled) {
          continue;
        }

        // Unique ID prevents duplicate reminders.
        final reminderId =
            'appointment_reminder_${appointmentDoc.id}_${now.year}_${now.month}_${now.day}';

        final reminderRef =
            _firestore
                .collection('notifications')
                .doc(reminderId);

        final existingReminder =
            await reminderRef.get();

        if (existingReminder.exists) {
          continue;
        }

        final token =
            (data['tokenCode'] ??
                    data['tokenNumber'] ??
                    '')
                .toString()
                .trim();

        final hospitalName =
            (data['hospitalName'] ??
                    'Hospital')
                .toString()
                .trim();

        final clinicName =
            (data['departmentName'] ??
                    data['clinicName'] ??
                    'OPD')
                .toString()
                .trim();

        final timeSlot =
            (data['timeSlot'] ??
                    data['startTime'] ??
                    '')
                .toString()
                .trim();

        String message =
            'You have an OPD appointment today';

        if (timeSlot.isNotEmpty) {
          message +=
              ' at $timeSlot';
        }

        message +=
            ' for $clinicName at $hospitalName.';

        if (token.isNotEmpty) {
          message +=
              ' Token: $token.';
        }

        message +=
            ' Please arrive on time.';

        await reminderRef.set({
          'type': 'reminder',
          'title': 'Appointment Reminder',
          'message': message,
          'status': 'NEW',
          'isRead': false,

          'userId':
              data['userId'] ??
                  data['patientId'] ??
                  identifier,

          'patientId':
              data['patientId'] ??
                  identifier,

          'patientNic':
              data['patientNic'] ?? '',

          'patientName':
              data['patientName'] ?? '',

          'appointmentId':
              appointmentDoc.id,

          'tokenNumber': token,
          'tokenCode': token,

          'hospitalName':
              hospitalName,

          'clinicName':
              clinicName,

          'departmentName':
              clinicName,

          'roomNumber':
              data['roomNumber'] ?? '',

          'appointmentDate':
              data['appointmentDate'],

          'timeSlot':
              data['timeSlot'] ?? '',

          'reminderTime':
              '06:00 AM',

          'createdAt':
              FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print(
        'Appointment reminder error: $e',
      );
    }
  }

  // ============================================================
  // APPOINTMENT DATE PARSER
  // ============================================================

  DateTime? _parseAppointmentDate(
    dynamic value,
  ) {
    try {
      if (value == null) {
        return null;
      }

      // Firestore Timestamp
      if (value is Timestamp) {
        return value.toDate();
      }

      final text =
          value.toString().trim();

      if (text.isEmpty) {
        return null;
      }

      // Example:
      // 2026-10-15
      // 2026-10-15T00:00:00
      final isoDate =
          DateTime.tryParse(text);

      if (isoDate != null) {
        return isoDate;
      }

      // Example:
      // 15/10/2026
      final parts =
          text.split('/');

      if (parts.length == 3) {
        final day =
            int.tryParse(parts[0]);

        final month =
            int.tryParse(parts[1]);

        final year =
            int.tryParse(parts[2]);

        if (day != null &&
            month != null &&
            year != null) {
          return DateTime(
            year,
            month,
            day,
          );
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // APPROACHING NOTIFICATION
  // ============================================================

  Future<String?> createApproachingNotification({
    required String userId,
    required String appointmentId,
    required String queueEntryId,
    required String queueSessionId,
    required int patientsAhead,
    bool isCaregiver = false,
  }) async {
    final int safePatientsAhead =
        patientsAhead < 0
            ? 0
            : patientsAhead;

    String message;

    if (safePatientsAhead == 1) {
      message = isCaregiver
          ? 'Only 1 patient is ahead. Please be ready to assist.'
          : 'Only 1 patient is ahead. Please get ready for your turn.';
    } else {
      message = isCaregiver
          ? '$safePatientsAhead patients are ahead. Please be ready to assist.'
          : '$safePatientsAhead patients are ahead. Please get ready for your turn.';
    }

    return createNotification(
      userId: userId,
      type: isCaregiver
          ? 'caregiver_queue_approaching'
          : 'queue_approaching',
      title: isCaregiver
          ? 'Queue Approaching'
          : 'Your Queue Is Approaching',
      message: message,
      appointmentId: appointmentId,
      queueEntryId: queueEntryId,
      queueSessionId: queueSessionId,
    );
  }

  // ============================================================
  // YOUR TURN NOTIFICATION
  // ============================================================

  Future<String?> createYourTurnNotification({
    required String userId,
    required String appointmentId,
    required String queueEntryId,
    required String queueSessionId,
    bool isCaregiver = false,
  }) async {
    return createNotification(
      userId: userId,
      type: isCaregiver
          ? 'caregiver_your_turn'
          : 'your_turn',
      title: isCaregiver
          ? 'Patient Turn Alert'
          : 'Your Turn',
      message: isCaregiver
          ? 'The patient is now due for their appointment. Please assist them.'
          : 'It is now your turn. Please proceed to the OPD.',
      appointmentId: appointmentId,
      queueEntryId: queueEntryId,
      queueSessionId: queueSessionId,
      isUrgent: true,
    );
  }

  // ============================================================
  // CREATE PATIENT + CAREGIVER APPROACHING ALERTS
  // ============================================================

  Future<List<String>> createApproachingAlerts({
    required String patientUid,
    required String caregiverUid,
    required String appointmentId,
    required String queueEntryId,
    required String queueSessionId,
    required int patientsAhead,
  }) async {
    final List<String> notificationIds = [];

    final patientNotificationId =
        await createApproachingNotification(
      userId: patientUid,
      appointmentId: appointmentId,
      queueEntryId: queueEntryId,
      queueSessionId: queueSessionId,
      patientsAhead: patientsAhead,
      isCaregiver: false,
    );

    if (patientNotificationId != null) {
      notificationIds.add(
        patientNotificationId,
      );
    }

    final caregiverNotificationId =
        await createApproachingNotification(
      userId: caregiverUid,
      appointmentId: appointmentId,
      queueEntryId: queueEntryId,
      queueSessionId: queueSessionId,
      patientsAhead: patientsAhead,
      isCaregiver: true,
    );

    if (caregiverNotificationId != null) {
      notificationIds.add(
        caregiverNotificationId,
      );
    }

    return notificationIds;
  }

  // ============================================================
  // CREATE PATIENT + CAREGIVER YOUR TURN ALERTS
  // ============================================================

  Future<List<String>> createYourTurnAlerts({
    required String patientUid,
    required String caregiverUid,
    required String appointmentId,
    required String queueEntryId,
    required String queueSessionId,
  }) async {
    final List<String> notificationIds = [];

    final patientNotificationId =
        await createYourTurnNotification(
      userId: patientUid,
      appointmentId: appointmentId,
      queueEntryId: queueEntryId,
      queueSessionId: queueSessionId,
      isCaregiver: false,
    );

    if (patientNotificationId != null) {
      notificationIds.add(
        patientNotificationId,
      );
    }

    final caregiverNotificationId =
        await createYourTurnNotification(
      userId: caregiverUid,
      appointmentId: appointmentId,
      queueEntryId: queueEntryId,
      queueSessionId: queueSessionId,
      isCaregiver: true,
    );

    if (caregiverNotificationId != null) {
      notificationIds.add(
        caregiverNotificationId,
      );
    }

    return notificationIds;
  }
}