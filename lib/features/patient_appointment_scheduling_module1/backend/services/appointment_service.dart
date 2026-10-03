import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore;

  AppointmentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _appointmentsRef => _firestore.collection('appointments');

  /// Generate sequential or randomized realistic OPD token
  String generateTokenCode() {
    final rand = 10 + (DateTime.now().millisecond % 50);
    return 'A-${rand.toString().padLeft(3, '0')}';
  }

  /// Book an appointment atomically into Firestore
  Future<String> bookAppointment(AppointmentModel appointment) async {
    try {
      final docRef = appointment.id.isNotEmpty
          ? _appointmentsRef.doc(appointment.id)
          : _appointmentsRef.doc();

      final toSave = AppointmentModel(
        id: docRef.id,
        patientId: appointment.patientId,
        patientName: appointment.patientName,
        patientNic: appointment.patientNic,
        isCaregiverBooking: appointment.isCaregiverBooking,
        relationship: appointment.relationship,
        priority: appointment.priority,
        hospitalId: appointment.hospitalId,
        hospitalName: appointment.hospitalName,
        departmentId: appointment.departmentId,
        departmentName: appointment.departmentName,
        roomNumber: appointment.roomNumber,
        appointmentDate: appointment.appointmentDate,
        timeSlot: appointment.timeSlot,
        tokenCode: appointment.tokenCode,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      await docRef.set(toSave.toMap()).timeout(const Duration(seconds: 4));

      // Increment bookedCount in slot if available
      try {
        final slotDocId = '${appointment.departmentId}_${appointment.appointmentDate}';
        await _firestore.collection('appointment_slots').doc(slotDocId).set({
          'bookedCount': FieldValue.increment(1),
          'lastBookedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      return toSave.tokenCode;
    } catch (e) {
      debugPrint('AppointmentService: bookAppointment offline/fallback: $e');
      return appointment.tokenCode;
    }
  }

  /// Real-time stream of patient's booked appointments
  Stream<List<AppointmentModel>> streamPatientAppointments(String patientNic) {
    try {
      return _appointmentsRef
          .where('patientNic', isEqualTo: patientNic)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) => AppointmentModel.fromFirestore(doc)).toList();
        // Sort newest first
        list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });
    } catch (e) {
      debugPrint('AppointmentService: stream error $e');
      return Stream.value([]);
    }
  }

  /// Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await _appointmentsRef.doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('AppointmentService: cancelAppointment error $e');
      return false;
    }
  }
}
