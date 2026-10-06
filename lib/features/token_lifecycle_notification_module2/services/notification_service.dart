import 'package:cloud_firestore/cloud_firestore.dart';

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

    // ----------------------------------------------------------
    // Patient notification
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // Caregiver notification
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // Patient urgent notification
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // Caregiver urgent notification
    // ----------------------------------------------------------

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