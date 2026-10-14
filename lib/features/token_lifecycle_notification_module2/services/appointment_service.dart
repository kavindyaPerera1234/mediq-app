import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';
import '../models/appointment_model.dart';
class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Set<String> _buildUserLookupIds(String patientId) {
    final ids = <String>{};
    if (patientId.trim().isNotEmpty) {
      ids.add(patientId.trim());
    }
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        if (user.nic != null && user.nic!.trim().isNotEmpty) {
          ids.add(user.nic!.trim());
        }
        if (user.phoneNumber.trim().isNotEmpty) {
          ids.add(user.phoneNumber.trim());
        }
        if (user.userId.trim().isNotEmpty) {
          ids.add(user.userId.trim());
        }
      }
    } catch (_) {}
    return ids;
  }
  /// Real-time stream of upcoming appointments so newly booked slots appear instantly
  Stream<List<AppointmentModel>> streamUpcomingAppointments(
    String patientId,
  ) {
    final ids = _buildUserLookupIds(patientId);
    return _firestore
        .collection('appointments')
        .snapshots()
        .map((snapshot) {
      final docs =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final pId = data['patientId']?.toString().trim();
        final pNic = data['patientNic']?.toString().trim();
        final uId = data['userId']?.toString().trim();
        final cId = data['caregiverId']?.toString().trim();
        if ((pId != null && ids.contains(pId)) ||
            (pNic != null && ids.contains(pNic)) ||
            (uId != null && ids.contains(uId)) ||
            (cId != null && ids.contains(cId))) {
          docs[doc.id] = doc;
        }
      }
      final list = docs.values
          .map(
            (doc) => AppointmentModel.fromFirestore(
              doc.id,
              doc.data()!,
            ),
          )
          .toList();
      list.sort(
        (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
      );
      return list;
    });
  }
  // Get upcoming appointments
  Future<List<AppointmentModel>> getUpcomingAppointments(
    String patientId,
  ) async {
    try {
      final ids = _buildUserLookupIds(patientId);
      final docs =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in ids) {
        final q1 = await _firestore
            .collection('appointments')
            .where('patientId', isEqualTo: id)
            .get();
        for (final doc in q1.docs) {
          docs[doc.id] = doc;
        }
        final q2 = await _firestore
            .collection('appointments')
            .where('patientNic', isEqualTo: id)
            .get();
        for (final doc in q2.docs) {
          docs[doc.id] = doc;
        }
        final q3 = await _firestore
            .collection('appointments')
            .where('userId', isEqualTo: id)
            .get();
        for (final doc in q3.docs) {
          docs[doc.id] = doc;
        }
        final q4 = await _firestore
            .collection('appointments')
            .where('caregiverId', isEqualTo: id)
            .get();
        for (final doc in q4.docs) {
          docs[doc.id] = doc;
        }
      }
      final list = docs.values
          .map(
            (doc) => AppointmentModel.fromFirestore(
              doc.id,
              doc.data()!,
            ),
          )
          .toList();
      list.sort(
        (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
      );
      return list;
    } catch (e) {
      debugPrint(
        'Firestore Error in getUpcomingAppointments: $e',
      );
      return [];
    }
  }
  // Get appointment history
  Future<List<AppointmentModel>> getAppointmentHistory(
    String patientId,
  ) async {
    try {
      final ids = _buildUserLookupIds(patientId);
      final docs =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in ids) {
        final q1 = await _firestore
            .collection('appointments')
            .where('patientId', isEqualTo: id)
            .get();
        for (final doc in q1.docs) {
          docs[doc.id] = doc;
        }
        final q2 = await _firestore
            .collection('appointments')
            .where('patientNic', isEqualTo: id)
            .get();
        for (final doc in q2.docs) {
          docs[doc.id] = doc;
        }
        final q3 = await _firestore
            .collection('appointments')
            .where('userId', isEqualTo: id)
            .get();
        for (final doc in q3.docs) {
          docs[doc.id] = doc;
        }
        final q4 = await _firestore
            .collection('appointments')
            .where('caregiverId', isEqualTo: id)
            .get();
        for (final doc in q4.docs) {
          docs[doc.id] = doc;
        }
      }
      final list = docs.values
          .map(
            (doc) => AppointmentModel.fromFirestore(
              doc.id,
              doc.data()!,
            ),
          )
          .toList();
      list.sort(
        (a, b) =>
            b.appointmentDate.compareTo(a.appointmentDate),
      );
      return list;
    } catch (e) {
      debugPrint(
        'Firestore Error in getAppointmentHistory: $e',
      );
      return [];
    }
  }
  // ============================================================
  // CREATE MISSED TOKEN NOTIFICATION
  // ============================================================
  Future<void> _createMissedTokenNotification({
    required String appointmentId,
    required Map<String, dynamic> appointmentData,
  }) async {
    try {
      final token =
          (appointmentData['tokenCode'] ??
                  appointmentData['tokenNumber'] ??
                  '')
              .toString();
      final department =
          (appointmentData['departmentName'] ??
                  appointmentData['clinicName'] ??
                  '')
              .toString();
      await _firestore
          .collection('notifications')
          .doc('missed_token_$appointmentId')
          .set({
        'type': 'missed_token',
        'title': 'Missed Token Alert',
        'message':
            'You missed token $token for $department.',
        'status': 'NEW',
        'isRead': false,
        'userId':
            appointmentData['userId'] ??
                appointmentData['patientId'],
        'patientId': appointmentData['patientId'],
        'patientNic': appointmentData['patientNic'],
        'patientName': appointmentData['patientName'],
        'appointmentId': appointmentId,
        'tokenNumber': token,
        'tokenCode': token,
        'hospitalName': appointmentData['hospitalName'],
        'clinicName':
            appointmentData['departmentName'] ??
                appointmentData['clinicName'],
        'departmentName':
            appointmentData['departmentName'],
        'roomNumber': appointmentData['roomNumber'],
        'appointmentDate':
            appointmentData['appointmentDate'],
        'timeSlot': appointmentData['timeSlot'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Missed token notification error: $e',
      );
    }
  }
  // ============================================================
  // CHECK SESSION END TIME
  // ============================================================
  bool _hasSessionEnded(
    Map<String, dynamic> appointmentData,
  ) {
    try {
      final dateText =
          (appointmentData['appointmentDate'] ?? '')
              .toString()
              .trim();
      final endTimeText =
          (appointmentData['endTime'] ?? '')
              .toString()
              .trim();
      if (dateText.isEmpty || endTimeText.isEmpty) {
        return false;
      }
      DateTime? date = DateTime.tryParse(dateText);
      if (date == null) {
        final dateParts = dateText.split('/');
        if (dateParts.length == 3) {
          final day = int.tryParse(dateParts[0]);
          final month = int.tryParse(dateParts[1]);
          final year = int.tryParse(dateParts[2]);
          if (day != null &&
              month != null &&
              year != null) {
            date = DateTime(
              year,
              month,
              day,
            );
          }
        }
      }
      if (date == null) {
        return false;
      }
      var cleanTime = endTimeText.toUpperCase().trim();
      final isPm = cleanTime.contains('PM');
      final isAm = cleanTime.contains('AM');
      cleanTime = cleanTime
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();
      final timeParts = cleanTime.split(':');
      if (timeParts.isEmpty) {
        return false;
      }
      var hour =
          int.tryParse(timeParts[0].trim()) ?? -1;
      final minute = timeParts.length > 1
          ? int.tryParse(timeParts[1].trim()) ?? 0
          : 0;
      if (hour < 0 || hour > 23) {
        return false;
      }
      if (isPm && hour < 12) {
        hour += 12;
      }
      if (isAm && hour == 12) {
        hour = 0;
      }
      final sessionEnd = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
      return !DateTime.now().isBefore(sessionEnd);
    } catch (e) {
      debugPrint(
        'AppointmentService session end check error: $e',
      );
      return false;
    }
  }
  // ============================================================
  // SYNC MISSED APPOINTMENTS
  // ============================================================
  Future<void> syncMissedAppointments(
    String patientId,
  ) async {
    try {
      final ids = _buildUserLookupIds(patientId);
      final appointmentSnap =
          await _firestore.collection('appointments').get();
      final queueSnap =
          await _firestore.collection('queue_entries').get();
      for (final appointmentDoc in appointmentSnap.docs) {
        final appointmentData = appointmentDoc.data();
        final pId = appointmentData['patientId']?.toString().trim();
        final pNic = appointmentData['patientNic']?.toString().trim();
        final uId = appointmentData['userId']?.toString().trim();
        final cId = appointmentData['caregiverId']?.toString().trim();
        final belongsToUser =
            (pId != null && ids.contains(pId)) ||
            (pNic != null && ids.contains(pNic)) ||
            (uId != null && ids.contains(uId)) ||
            (cId != null && ids.contains(cId));
        if (!belongsToUser) {
          continue;
        }
        final appointmentStatus =
            (appointmentData['status'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
        if (appointmentStatus == 'completed' ||
            appointmentStatus == 'cancelled') {
          continue;
        }
        QueryDocumentSnapshot<Map<String, dynamic>>? currentQueueDoc;
        for (final queueDoc in queueSnap.docs) {
          final queueData = queueDoc.data();
          final queueAppointmentId =
              (queueData['appointmentId'] ?? '').toString();
          if (queueDoc.id == appointmentDoc.id ||
              queueAppointmentId == appointmentDoc.id) {
            currentQueueDoc = queueDoc;
            break;
          }
        }
        // ============================================================
        // SESSION ENDED
        // ============================================================
        // When the appointment session has ended:
        // 1. If there is no queue entry, cancel the expired active
        //    appointment so it leaves Upcoming and appears in Cancelled.
        // 2. If there is a queue entry and the patient did not attend,
        //    mark the queue entry as missed and cancel the appointment.
        // 3. Do not cancel a patient who is already serving,
        //    in consultation, completed, arrived or on hold.
        // ============================================================
        if (_hasSessionEnded(appointmentData)) {
          if (currentQueueDoc == null) {
            await _firestore
                .collection('appointments')
                .doc(appointmentDoc.id)
                .update({
              'status': 'cancelled',
              'cancelReason': 'session_ended',
              'cancelledAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            continue;
          }
          final currentQueueData = currentQueueDoc.data();
          final currentQueueStatus =
              (currentQueueData['status'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
          final alreadyAttended =
              currentQueueStatus == 'completed' ||
              currentQueueStatus == 'serving' ||
              currentQueueStatus == 'in_consultation' ||
              currentQueueStatus == 'arrived' ||
              currentQueueStatus == 'on_hold';
          if (alreadyAttended) {
            continue;
          }
          final didNotAttend =
              currentQueueStatus == 'waiting' ||
              currentQueueStatus == 'called' ||
              currentQueueStatus == 'missed' ||
              currentQueueStatus == 'confirmed' ||
              currentQueueStatus == 'scheduled' ||
              currentQueueStatus == 'rescheduled' ||
              currentQueueStatus.isEmpty;
          if (didNotAttend) {
            if (currentQueueStatus != 'missed') {
              await _firestore
                  .collection('queue_entries')
                  .doc(currentQueueDoc.id)
                  .update({
                'status': 'missed',
                'missedAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              await _createMissedTokenNotification(
                appointmentId: appointmentDoc.id,
                appointmentData: appointmentData,
              );
            }
            await _firestore
                .collection('appointments')
                .doc(appointmentDoc.id)
                .update({
              'status': 'cancelled',
              'cancelReason': currentQueueStatus == 'missed'
                  ? 'missed_token'
                  : 'session_ended',
              'cancelledAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          continue;
        }
        // Session is still active. If there is no queue entry yet,
        // there is nothing else to sync for this appointment.
        if (currentQueueDoc == null) {
          continue;
        }
        final currentQueueData = currentQueueDoc.data();
        final currentQueueStatus =
            (currentQueueData['status'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
        // ============================================================
        // PATIENT ALREADY ATTENDED / FINISHED
        // ============================================================
        if (currentQueueStatus == 'completed' ||
            currentQueueStatus == 'serving' ||
            currentQueueStatus == 'in_consultation' ||
            currentQueueStatus == 'arrived' ||
            currentQueueStatus == 'cancelled' ||
            currentQueueStatus == 'on_hold') {
          continue;
        }
        // Token was already missed, but session is still active.
        // Keep the appointment active until the session ends.
        if (currentQueueStatus == 'missed') {
          continue;
        }
        final queueSessionId =
            (currentQueueData['queueSessionId'] ?? '').toString();
        final currentOrder = currentQueueData['queueOrder'] is num
            ? (currentQueueData['queueOrder'] as num).toInt()
            : 0;
        if (queueSessionId.isEmpty || currentOrder <= 0) {
          continue;
        }
        bool tokenPassed = false;
        for (final otherQueueDoc in queueSnap.docs) {
          final otherData = otherQueueDoc.data();
          final otherSessionId =
              (otherData['queueSessionId'] ?? '').toString();
          if (otherSessionId != queueSessionId) {
            continue;
          }
          final otherOrder = otherData['queueOrder'] is num
              ? (otherData['queueOrder'] as num).toInt()
              : 0;
          final otherStatus =
              (otherData['status'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
          final progressed =
              otherStatus == 'called' ||
              otherStatus == 'serving' ||
              otherStatus == 'in_consultation' ||
              otherStatus == 'completed';
          if (progressed && otherOrder > currentOrder) {
            tokenPassed = true;
            break;
          }
        }
        if (!tokenPassed) {
          continue;
        }
        // ============================================================
        // TOKEN PASSED BEFORE SESSION END
        // ============================================================
        // Example:
        // A-005 waiting -> A-006 called
        // A-005 becomes missed.
        // Appointment is NOT cancelled until the session ends.
        // ============================================================
        await _firestore
            .collection('queue_entries')
            .doc(currentQueueDoc.id)
            .update({
          'status': 'missed',
          'missedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _createMissedTokenNotification(
          appointmentId: appointmentDoc.id,
          appointmentData: appointmentData,
        );
      }
    } catch (e) {
      debugPrint(
        'AppointmentService: syncMissedAppointments error: $e',
      );
    }
  }
  // Reschedule appointment
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required String newDate,
    required String newStartTime,
    required String newEndTime,
    required String newSlotId,
  }) async {
    await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'slotId': newSlotId,
      'appointmentDate': newDate,
      'startTime': newStartTime,
      'endTime': newEndTime,
      'status': 'rescheduled',
      'updatedAt': Timestamp.now(),
    });
  }
  // Cancel appointment
  Future<void> cancelAppointment(
    String appointmentId,
  ) async {
    await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'status': 'cancelled',
      'cancelledAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    try {
      final queueSnapshot =
          await _firestore
              .collection('queue_entries')
              .where(
                'appointmentId',
                isEqualTo: appointmentId,
              )
              .get();
      for (final queueDoc
          in queueSnapshot.docs) {
        await queueDoc.reference.update({
          'status': 'cancelled',
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (_) {}
  }
  // ============================================================
  // DELETE CANCELLED APPOINTMENT
  // ============================================================
  Future<void> deleteCancelledAppointment(
    String appointmentId,
  ) async {
    final appointmentRef = _firestore
        .collection('appointments')
        .doc(appointmentId);
    final appointmentDoc =
        await appointmentRef.get();
    if (!appointmentDoc.exists) {
      return;
    }
    final data = appointmentDoc.data();
    final status =
        (data?['status'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
    if (status != 'cancelled') {
      throw Exception(
        'Only cancelled appointments can be deleted.',
      );
    }
    try {
      final queueSnapshot =
          await _firestore
              .collection('queue_entries')
              .where(
                'appointmentId',
                isEqualTo: appointmentId,
              )
              .get();
      for (final queueDoc
          in queueSnapshot.docs) {
        await queueDoc.reference.delete();
      }
    } catch (e) {
      debugPrint(
        'Unable to delete related queue entries: $e',
      );
    }
    try {
      final notificationSnapshot =
          await _firestore
              .collection('notifications')
              .where(
                'appointmentId',
                isEqualTo: appointmentId,
              )
              .get();
      for (final notificationDoc
          in notificationSnapshot.docs) {
        await notificationDoc.reference.delete();
      }
    } catch (e) {
      debugPrint(
        'Unable to delete related notifications: $e',
      );
    }
    await appointmentRef.delete();
  }
}
