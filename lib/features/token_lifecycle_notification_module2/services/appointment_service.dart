import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<String> _buildUserLookupIds(String patientId) {
    final ids = <String>{};
    if (patientId.trim().isNotEmpty) ids.add(patientId.trim());
    final user = AuthService().currentUser;
    if (user != null) {
      if (user.nic != null && user.nic!.trim().isNotEmpty) ids.add(user.nic!.trim());
      if (user.phoneNumber.trim().isNotEmpty) ids.add(user.phoneNumber.trim());
      if (user.userId.trim().isNotEmpty) ids.add(user.userId.trim());
    }
    return ids;
  }

  // Get upcoming appointments
  Future<List<AppointmentModel>> getUpcomingAppointments(String patientId) async {
    try {
      final ids = _buildUserLookupIds(patientId);
      final docs = <String, DocumentSnapshot<Map<String, dynamic>>>{};

      for (final id in ids) {
        final q1 = await _firestore.collection('appointments').where('patientId', isEqualTo: id).get();
        for (final doc in q1.docs) {
          docs[doc.id] = doc;
        }
        final q2 = await _firestore.collection('appointments').where('patientNic', isEqualTo: id).get();
        for (final doc in q2.docs) {
          docs[doc.id] = doc;
        }
        final q3 = await _firestore.collection('appointments').where('userId', isEqualTo: id).get();
        for (final doc in q3.docs) {
          docs[doc.id] = doc;
        }
        final q4 = await _firestore.collection('appointments').where('caregiverId', isEqualTo: id).get();
        for (final doc in q4.docs) {
          docs[doc.id] = doc;
        }
      }

      final list = docs.values.map((doc) => AppointmentModel.fromFirestore(doc.id, doc.data()!)).toList();
      list.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return list;
    } catch (e) {
      debugPrint("Firestore Error in getUpcomingAppointments: $e");
      return [];
    }
  }

  // Get appointment history
  Future<List<AppointmentModel>> getAppointmentHistory(String patientId) async {
    try {
      final ids = _buildUserLookupIds(patientId);
      final docs = <String, DocumentSnapshot<Map<String, dynamic>>>{};

      for (final id in ids) {
        final q1 = await _firestore.collection('appointments').where('patientId', isEqualTo: id).get();
        for (final doc in q1.docs) {
          docs[doc.id] = doc;
        }
        final q2 = await _firestore.collection('appointments').where('patientNic', isEqualTo: id).get();
        for (final doc in q2.docs) {
          docs[doc.id] = doc;
        }
        final q3 = await _firestore.collection('appointments').where('userId', isEqualTo: id).get();
        for (final doc in q3.docs) {
          docs[doc.id] = doc;
        }
        final q4 = await _firestore.collection('appointments').where('caregiverId', isEqualTo: id).get();
        for (final doc in q4.docs) {
          docs[doc.id] = doc;
        }
      }

      final list = docs.values.map((doc) => AppointmentModel.fromFirestore(doc.id, doc.data()!)).toList();
      list.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return list;
    } catch (e) {
      debugPrint("Firestore Error in getAppointmentHistory: $e");
      return [];
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
      await _firestore.collection('queue_entries').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
    } catch (_) {}
  }
}