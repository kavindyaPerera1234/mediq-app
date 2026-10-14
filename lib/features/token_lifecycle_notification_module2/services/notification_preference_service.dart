import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPreferenceService {
  NotificationPreferenceService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<bool> isEnabled({
    required String userId,
    required String type,
  }) async {
    try {
      final cleanUserId =
          userId.trim();

      if (cleanUserId.isEmpty) {
        return true;
      }

      final document = await _firestore
          .collection('users')
          .doc(cleanUserId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (!document.exists ||
          document.data() == null) {
        return true;
      }

      final data = document.data()!;

      final appNotifications =
          data['appNotifications'];

      if (appNotifications is bool &&
          appNotifications == false) {
        return false;
      }

      final cleanType =
          type.trim().toLowerCase();

      if (cleanType ==
          'appointment_confirmed') {
        return data[
                    'appointmentConfirmation'] !=
                false;
      }

      if (cleanType ==
              'near_turn' ||
          cleanType ==
              'queue_approaching' ||
          cleanType ==
              'caregiver_queue_approaching') {
        return data[
                    'queueApproaching'] !=
                false;
      }

      if (cleanType ==
              'queue_delay' ||
          cleanType == 'delay' ||
          cleanType ==
              'delay_broadcast' ||
          cleanType ==
              'queue_delayed') {
        return data['opdDelay'] !=
            false;
      }

      if (cleanType ==
              'reminder' ||
          cleanType ==
              'appointment_reminder' ||
          cleanType ==
              'opd_reminder') {
        return data[
                    'appointmentReminder'] !=
                false;
      }

      return true;
    } catch (e) {
      return true;
    }
  }
}