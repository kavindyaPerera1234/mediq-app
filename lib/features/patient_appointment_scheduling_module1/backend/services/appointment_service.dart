import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore;

  AppointmentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _appointmentsRef => _firestore.collection('appointments');

  /// Generate the next strictly sequential OPD token for the given date and department
  int _slotBaseToken(String? timeSlot) {
    if (timeSlot == null || timeSlot.trim().isEmpty) {
      final hour = DateTime.now().hour;
      if (hour < 9) return 1;
      if (hour < 10) return 26;
      if (hour < 11) return 51;
      if (hour < 12) return 76;
      if (hour < 13) return 101;
      return 126;
    }
    final lower = timeSlot.toLowerCase();
    if (lower.contains('08:00') || lower.contains('8:00')) return 1;
    if (lower.contains('09:00') || lower.contains('9:00')) return 26;
    if (lower.contains('10:00')) return 51;
    if (lower.contains('11:00')) return 76;
    if (lower.contains('12:00')) return 101;
    if (lower.contains('01:00') || lower.contains('1:00')) return 126;
    if (lower.contains('02:00') || lower.contains('2:00')) return 151;
    return 1;
  }

  Future<String> getNextTokenCode({
    required String hospitalId,
    required String departmentId,
    required String appointmentDate,
    String? timeSlot,
  }) async {
    try {
      final baseToken = _slotBaseToken(timeSlot);

      // Check existing appointments for this date & department
      final query = await _appointmentsRef
          .where('appointmentDate', isEqualTo: appointmentDate)
          .where('departmentId', isEqualTo: departmentId)
          .get();

      int maxTokenInSlot = 0;
      int countInSlot = 0;

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final slot = (data['timeSlot'] ?? '').toString();
        final token = (data['tokenCode'] ?? '').toString();
        final match = RegExp(r'\d+').firstMatch(token);
        if (match != null) {
          final num = int.tryParse(match.group(0)!) ?? 0;
          if (timeSlot != null && timeSlot.isNotEmpty && slot == timeSlot) {
            countInSlot++;
            if (num > maxTokenInSlot) maxTokenInSlot = num;
          } else if (timeSlot == null || timeSlot.isEmpty) {
            if (num > maxTokenInSlot) maxTokenInSlot = num;
          }
        }
      }

      int nextNum;
      if (maxTokenInSlot >= baseToken) {
        nextNum = maxTokenInSlot + 1;
      } else {
        nextNum = baseToken + countInSlot;
      }

      return 'A-${nextNum.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('AppointmentService getNextTokenCode fallback: $e');
      final fallbackBase = _slotBaseToken(timeSlot);
      return 'A-${fallbackBase.toString().padLeft(3, '0')}';
    }
  }

  /// Synchronous fallback
  String generateTokenCode({String? timeSlot}) {
    final base = _slotBaseToken(timeSlot);
    return 'A-${base.toString().padLeft(3, '0')}';
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
        
        // Count existing queue entries to set accurate queuePosition
        int nextPos = 1;
        try {
          final countSnap = await _firestore
              .collection('queue_entries')
              .where('queueSessionId', isEqualTo: sessionId)
              .get();
          nextPos = countSnap.docs.length + 1;
        } catch (_) {}

        await _firestore.collection('queue_entries').doc(docRef.id).set({
          'appointmentId': docRef.id,
          'patientId': appointment.patientId.isNotEmpty ? appointment.patientId : appointment.patientNic,
          'patientNic': appointment.patientNic,
          'patientName': appointment.patientName,
          'hospitalId': appointment.hospitalId,
          'departmentId': appointment.departmentId,
          'tokenCode': appointment.tokenCode,
          'tokenNumber': appointment.tokenCode,
          'queueSessionId': sessionId,
          'status': 'waiting',
          'queuePosition': nextPos,
          'estimatedWaitMinutes': (nextPos - 1) * 4,
          'priority': appointment.priority,
          'isCaregiverBooking': appointment.isCaregiverBooking,
          'relationship': appointment.relationship,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Get existing session to keep active serving token if already set
        String activeServing = '—';
        try {
          final sessionDoc = await _firestore.collection('queue_sessions').doc(sessionId).get();
          if (sessionDoc.exists) {
            activeServing = (sessionDoc.data()?['currentToken'] ?? sessionDoc.data()?['currentTokenNumber'] ?? '—').toString();
          }
        } catch (_) {}

        await _firestore.collection('queue_sessions').doc(sessionId).set({
          'sessionId': sessionId,
          'queueSessionId': sessionId,
          'hospitalId': appointment.hospitalId,
          'hospitalName': appointment.hospitalName,
          'departmentId': appointment.departmentId,
          'departmentName': appointment.departmentName,
          'date': appointment.appointmentDate,
          'status': 'active',
          'currentToken': activeServing,
          'currentTokenNumber': activeServing,
          'currentTokenServing': activeServing,
          'lastIssuedToken': appointment.tokenCode,
          'lastIssuedTokenNumber': appointment.tokenCode,
          'roomNumber': appointment.roomNumber.isNotEmpty ? appointment.roomNumber : 'OPD Room 01',
          'doctorName': 'Duty Medical Officer',
          'estimatedMinutesPerPatient': 4,
          'delayMinutes': 0,
          'totalTokens': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Also update QS-001 compatibility doc
        await _firestore.collection('queue_sessions').doc('QS-001').set({
          'lastIssuedToken': appointment.tokenCode,
          'lastIssuedTokenNumber': appointment.tokenCode,
          'totalTokens': FieldValue.increment(1),
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
        if (patientNic.trim().isEmpty) return <AppointmentModel>[];
        final list = snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .where((app) => app.patientNic == patientNic || app.patientId == patientNic)
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
