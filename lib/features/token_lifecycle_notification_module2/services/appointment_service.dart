import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
class AppointmentService {

    final FirebaseFirestore _firestore =
        FirebaseFirestore.instance;
        // Get upcoming appointments
        Future<List<AppointmentModel>> getUpcomingAppointments(
        String patientId,
    ) async {
    try {
        print("Searching patient id: $patientId");
        final snapshot = await _firestore
        .collection('appointments')
        .where(
            'patientId',
            isEqualTo: patientId,
        )
        .get();

        print("Found documents: ${snapshot.docs.length}");
        return snapshot.docs.map((doc) {
            return AppointmentModel.fromFirestore(
                doc.id,
                doc.data(),
            );
        }).toList();

    } catch (e) {
        print("Firestore Error: $e");
        return [];

    }
  }
  // Get appointment history
  Future<List<AppointmentModel>> getAppointmentHistory(
      String patientId,
  ) async {
    final snapshot = await _firestore
    .collection('appointments')
    .where(
        'patientId',
        isEqualTo: patientId,
    )
    .get();
    return snapshot.docs.map((doc) {
        return AppointmentModel.fromFirestore(
            doc.id,
            doc.data(),
        );

    }).toList();

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
  }
}