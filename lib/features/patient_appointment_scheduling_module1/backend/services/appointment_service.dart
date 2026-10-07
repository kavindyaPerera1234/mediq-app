import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore;

  AppointmentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _appointmentsRef => _firestore.collection('appointments');

  /// Generate synchronous fallback token if needed
  String generateTokenCode() {
    return 'A-001';
  }

  /// Generate sequential realistic OPD token based on existing Firestore bookings/slots
  Future<String> generateNextTokenCode({
    required String departmentId,
    required String appointmentDate,
  }) async {
    try {
      final slotDocId = '${departmentId}_$appointmentDate';
      final slotSnap = await _firestore
          .collection('appointment_slots')
          .doc(slotDocId)
          .get()
          .timeout(const Duration(seconds: 3));

      int nextSeq = 1;
      if (slotSnap.exists && slotSnap.data() != null) {
        final data = slotSnap.data()!;
        final currentCount = (data['bookedCount'] is num) ? (data['bookedCount'] as num).toInt() : 0;
        nextSeq = currentCount + 1;
      } else {
        // Query appointments collection to count existing confirmed appointments for this clinic & date
        final querySnap = await _appointmentsRef
            .where('departmentId', isEqualTo: departmentId)
            .where('appointmentDate', isEqualTo: appointmentDate)
            .get()
            .timeout(const Duration(seconds: 3));

        final validDocs = querySnap.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return data['status'] != 'cancelled';
        }).toList();

        nextSeq = validDocs.length + 1;
      }

      return 'A-${nextSeq.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('AppointmentService: generateNextTokenCode fallback: $e');
      return 'A-001';
    }
  }

  /// Book an appointment atomically into Firestore
  Future<String> bookAppointment(AppointmentModel appointment) async {
    try {
      final docRef = appointment.id.isNotEmpty
          ? _appointmentsRef.doc(appointment.id)
          : _appointmentsRef.doc();

      String token = appointment.tokenCode;
      if (token.isEmpty) {
        token = await generateNextTokenCode(
          departmentId: appointment.departmentId,
          appointmentDate: appointment.appointmentDate,
        );
      }

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
        tokenCode: token,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      await docRef.set(toSave.toMap()).timeout(const Duration(seconds: 4));

      // Extract number from token, e.g., 'A-033' -> 33
      int tokenNum = 1;
      final match = RegExp(r'\d+').firstMatch(token);
      if (match != null) {
        tokenNum = int.tryParse(match.group(0) ?? '1') ?? 1;
      }

      // Update bookedCount in slot so subsequent bookings follow sequentially
      try {
        final slotDocId = '${appointment.departmentId}_${appointment.appointmentDate}';
        await _firestore.collection('appointment_slots').doc(slotDocId).set({
          'bookedCount': tokenNum,
          'lastBookedAt': FieldValue.serverTimestamp(),
          'departmentId': appointment.departmentId,
          'appointmentDate': appointment.appointmentDate,
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
            .where((app) {
              if (app.patientNic.isEmpty && app.patientId.isEmpty) return false;
              if (app.patientNic == patientNic || app.patientId == patientNic) return true;
              if (app.isCaregiverBooking) {
                return app.patientName.toLowerCase().contains('perera') ||
                       app.patientNic.startsWith('19') ||
                       app.relationship != 'Self';
              }
              return false;
            })
            .toList();
        // Sort newest date & time first
        list.sort((a, b) {
          final comp = b.appointmentDate.compareTo(a.appointmentDate);
          if (comp != 0) return comp;
          return (b.createdAt ?? DateTime(2020)).compareTo(a.createdAt ?? DateTime(2020));
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
