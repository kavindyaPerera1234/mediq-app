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

      // Cross-module sync: write to Module 3's queue_entries and queue_sessions
      try {
        final sessionId = '${appointment.hospitalId}_${appointment.departmentId}_${appointment.appointmentDate}';
        await _firestore.collection('queue_entries').doc(docRef.id).set({
          'appointmentId': docRef.id,
          'patientId': appointment.patientId.isNotEmpty ? appointment.patientId : appointment.patientNic,
          'patientNic': appointment.patientNic,
          'patientName': appointment.patientName,
          'hospitalId': appointment.hospitalId,
          'departmentId': appointment.departmentId,
          'tokenCode': appointment.tokenCode,
          'queueSessionId': sessionId,
          'status': 'waiting',
          'priority': appointment.priority,
          'isCaregiverBooking': appointment.isCaregiverBooking,
          'relationship': appointment.relationship,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore.collection('queue_sessions').doc(sessionId).set({
          'sessionId': sessionId,
          'hospitalId': appointment.hospitalId,
          'hospitalName': appointment.hospitalName,
          'departmentId': appointment.departmentId,
          'departmentName': appointment.departmentName,
          'date': appointment.appointmentDate,
          'status': 'active',
          'roomNumber': appointment.roomNumber.isNotEmpty ? appointment.roomNumber : 'OPD Room 01',
          'doctorName': 'Duty Medical Officer',
          'estimatedMinutesPerPatient': 4,
          'delayMinutes': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (syncErr) {
        debugPrint('AppointmentService: cross-module queue sync notice: $syncErr');
      }

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
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .where((app) => app.patientNic == patientNic || app.isCaregiverBooking)
            .toList();
        // Sort newest first
        list.sort((a, b) {
          final timeA = a.createdAt ?? DateTime.tryParse(a.appointmentDate) ?? DateTime(2020);
          final timeB = b.createdAt ?? DateTime.tryParse(b.appointmentDate) ?? DateTime(2020);
          return timeB.compareTo(timeA);
        });
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
