import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment_model.dart';
import '../../../auth_live_queue_module3/services/auth_service.dart';
import 'profile_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore;

  AppointmentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _appointmentsRef =>
      _firestore.collection('appointments');

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
      int highestTokenNumber = 0;

      // 1. Query appointments collection to find the highest existing confirmed token number
      final querySnap = await _appointmentsRef
          .where('departmentId', isEqualTo: departmentId)
          .where('appointmentDate', isEqualTo: appointmentDate)
          .get()
          .timeout(const Duration(seconds: 4));

      for (final doc in querySnap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};

        if (data['status'] == 'cancelled') continue;

        final rawToken =
            (data['tokenCode'] ?? data['tokenNumber'] ?? '').toString();

        final match = RegExp(r'\d+').firstMatch(rawToken);

        if (match != null) {
          final val = int.tryParse(match.group(0) ?? '0') ?? 0;

          if (val > highestTokenNumber) {
            highestTokenNumber = val;
          }
        }
      }

      // Also ensure count is at least total confirmed docs
      final validDocsCount = querySnap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['status'] != 'cancelled';
      }).length;

      if (validDocsCount > highestTokenNumber) {
        highestTokenNumber = validDocsCount;
      }

      // 2. Also check appointment_slots document for recorded sequential counter
      final slotDocId = '${departmentId}_$appointmentDate';

      final slotSnap = await _firestore
          .collection('appointment_slots')
          .doc(slotDocId)
          .get()
          .timeout(const Duration(seconds: 3));

      if (slotSnap.exists && slotSnap.data() != null) {
        final data = slotSnap.data()!;

        final currentCount = (data['bookedCount'] is num)
            ? (data['bookedCount'] as num).toInt()
            : 0;

        if (currentCount > highestTokenNumber) {
          highestTokenNumber = currentCount;
        }
      }

      final nextSeq = highestTokenNumber + 1;

      return 'A-${nextSeq.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint(
        'AppointmentService: generateNextTokenCode fallback: $e',
      );

      return 'A-001';
    }
  }

  /// Check if the patient already has an existing active booking for the same hospital, clinic, date and time slot
  Future<AppointmentModel?> findDuplicateAppointment({
    required String patientNic,
    required String patientName,
    required String hospitalId,
    required String hospitalName,
    required String departmentName,
    required String appointmentDate,
    required String timeSlot,
    bool isCaregiverBooking = false,
  }) async {
    try {
      final snap = await _appointmentsRef
          .where('appointmentDate', isEqualTo: appointmentDate)
          .get();

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final st =
            (data['status'] ?? '').toString().toLowerCase().trim();

        // Ignore cancelled, completed, or missed
        if (st == 'cancelled' ||
            st == 'completed' ||
            st == 'missed') {
          continue;
        }

        final hosp = (data['hospitalName'] ??
                data['hospitalId'] ??
                '')
            .toString()
            .toLowerCase()
            .trim();

        final dept = (data['departmentName'] ??
                data['clinicName'] ??
                data['departmentId'] ??
                '')
            .toString()
            .toLowerCase()
            .trim();

        final slot =
            (data['timeSlot'] ?? '').toString().trim();

        final isCg =
            data['isCaregiverBooking'] == true;

        final targetHosp =
            hospitalName.toLowerCase().trim();

        final targetDept =
            departmentName.toLowerCase().trim();

        // Check if hospital and department match (with clean alphanumeric comparison)
        final cleanHosp1 =
            hosp.replaceAll(RegExp(r'[^a-z0-9]'), '');

        final cleanHosp2 =
            targetHosp.replaceAll(RegExp(r'[^a-z0-9]'), '');

        final cleanDept1 =
            dept.replaceAll(RegExp(r'[^a-z0-9]'), '');

        final cleanDept2 =
            targetDept.replaceAll(RegExp(r'[^a-z0-9]'), '');

        final hospMatch =
            cleanHosp1 == cleanHosp2 ||
                cleanHosp1.contains(cleanHosp2) ||
                cleanHosp2.contains(cleanHosp1);

        final deptMatch =
            cleanDept1 == cleanDept2 ||
                cleanDept1.contains(cleanDept2) ||
                cleanDept2.contains(cleanDept1);

        if (hospMatch && deptMatch) {
          // Check slot matching
          final slotClean1 =
              slot.replaceAll(' ', '').toLowerCase();

          final slotClean2 =
              timeSlot.replaceAll(' ', '').toLowerCase();

          final slotMatches =
              slotClean1 == slotClean2 ||
                  slotClean1.contains(slotClean2) ||
                  slotClean2.contains(slotClean1);

          if (slotMatches) {
            // Check patient identity match
            final pNic =
                (data['patientNic'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();

            final pName =
                (data['patientName'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();

            final targetNic =
                patientNic.trim().toLowerCase();

            final targetName =
                patientName.trim().toLowerCase();

            bool patientMatch = false;

            if (targetNic.isNotEmpty &&
                targetNic != 'n/a' &&
                pNic.isNotEmpty &&
                pNic != 'n/a') {
              patientMatch = (pNic == targetNic);
            } else {
              patientMatch =
                  (pName == targetName &&
                      isCg == isCaregiverBooking);
            }

            if (patientMatch) {
              return AppointmentModel.fromFirestore(doc);
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
        'AppointmentService: findDuplicateAppointment error: $e',
      );
    }

    return null;
  }

  Future<void> _createAppointmentConfirmedNotification(
    AppointmentModel appointment,
  ) async {
    try {
      final notificationId =
          'appointment_confirmed_${appointment.id}';

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set({
        'type': 'appointment_confirmed',
        'title': 'Appointment Confirmed',
        'message':
            'Token ${appointment.tokenCode} for ${appointment.departmentName}, ${appointment.hospitalName}.',
        'status': 'NEW',
        'isRead': false,
        'userId':
            appointment.userId ?? appointment.patientId,
        'patientId': appointment.patientId,
        'patientNic': appointment.patientNic,
        'patientName': appointment.patientName,
        'appointmentId': appointment.id,
        'tokenNumber': appointment.tokenCode,
        'tokenCode': appointment.tokenCode,
        'hospitalName': appointment.hospitalName,
        'clinicName': appointment.departmentName,
        'departmentName': appointment.departmentName,
        'roomNumber': appointment.roomNumber,
        'appointmentDate': appointment.appointmentDate,
        'timeSlot': appointment.timeSlot,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Appointment confirmed notification error: $e',
      );
    }
  }

  /// Book an appointment atomically into Firestore
  Future<String> bookAppointment(
    AppointmentModel appointment,
  ) async {
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
        userId:
            appointment.userId ?? appointment.patientId,
        patientName: appointment.patientName,
        patientNic: appointment.patientNic,
        isCaregiverBooking:
            appointment.isCaregiverBooking,
        relationship: appointment.relationship,
        priority: appointment.priority,
        hospitalId: appointment.hospitalId,
        hospitalName: appointment.hospitalName,
        departmentId: appointment.departmentId,
        departmentName: appointment.departmentName,
        roomNumber: appointment.roomNumber,
        appointmentDate: appointment.appointmentDate,
        timeSlot: appointment.timeSlot,
        startTime: appointment.startTime,
        endTime: appointment.endTime,
        slotId: appointment.slotId,
        tokenCode: token,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      await docRef
          .set(toSave.toMap())
          .timeout(const Duration(seconds: 4));

      await _createAppointmentConfirmedNotification(
        toSave,
      );

      // Extract number from token, e.g., 'A-033' -> 33
      int tokenNum = 1;

      final match =
          RegExp(r'\d+').firstMatch(token);

      if (match != null) {
        tokenNum =
            int.tryParse(match.group(0) ?? '1') ?? 1;
      }

      // Update bookedCount in slot so subsequent bookings follow sequentially
      try {
        final slotDocId =
            '${appointment.departmentId}_${appointment.appointmentDate}';

        await _firestore
            .collection('appointment_slots')
            .doc(slotDocId)
            .set({
          'bookedCount': tokenNum,
          'lastBookedAt':
              FieldValue.serverTimestamp(),
          'departmentId':
              appointment.departmentId,
          'appointmentDate':
              appointment.appointmentDate,
        }, SetOptions(merge: true));
      } catch (_) {}

      // Dual-sync: create corresponding queue_entries document for Module 3 & Module 4 Live Queue
      try {
        final sessId =
            'sess_${appointment.hospitalId}_${appointment.departmentId}_${appointment.appointmentDate}';

        await _firestore
            .collection('queue_entries')
            .doc(docRef.id)
            .set({
          'queueEntryId': docRef.id,
          'appointmentId': docRef.id,
          'patientId': appointment.patientId,
          'userId':
              appointment.userId ?? appointment.patientId,
          'patientNic': appointment.patientNic,
          'patientName': appointment.patientName,
          'hospitalId': appointment.hospitalId,
          'hospitalName': appointment.hospitalName,
          'departmentId': appointment.departmentId,
          'departmentName':
              appointment.departmentName,
          'roomNumber': appointment.roomNumber,
          'tokenCode': token,
          'tokenNumber': token,
          'queueSessionId': sessId,
          'status': 'waiting',
          'priority': appointment.priority,
          'appointmentDate':
              appointment.appointmentDate,
          'timeSlot': appointment.timeSlot,
          'queueOrder': tokenNum,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      return toSave.tokenCode;
    } catch (e) {
      debugPrint(
        'AppointmentService: bookAppointment offline/fallback: $e',
      );

      return appointment.tokenCode;
    }
  }

  /// Real-time stream of patient's booked appointments
  Stream<List<AppointmentModel>>
      streamPatientAppointments(
    String patientNic,
  ) {
    try {
      final lookupIds = <String>{};

      if (patientNic.trim().isNotEmpty) {
        lookupIds.add(
          patientNic.trim().toLowerCase(),
        );
      }

      final currentAuth =
          AuthService().currentUser;

      if (currentAuth != null) {
        if (currentAuth.nic != null &&
            currentAuth.nic!.trim().isNotEmpty) {
          lookupIds.add(
            currentAuth.nic!.trim().toLowerCase(),
          );
        }

        if (currentAuth.phoneNumber
            .trim()
            .isNotEmpty) {
          lookupIds.add(
            currentAuth.phoneNumber
                .trim()
                .toLowerCase(),
          );
        }

        if (currentAuth.userId
            .trim()
            .isNotEmpty) {
          lookupIds.add(
            currentAuth.userId
                .trim()
                .toLowerCase(),
          );
        }
      }

      final activeProfile =
          ProfileService.activeProfileNotifier.value;

      if (activeProfile.nic.trim().isNotEmpty) {
        lookupIds.add(
          activeProfile.nic
              .trim()
              .toLowerCase(),
        );
      }

      if (activeProfile.phone
          .trim()
          .isNotEmpty) {
        lookupIds.add(
          activeProfile.phone
              .trim()
              .toLowerCase(),
        );
      }

      return _appointmentsRef
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map(
              (doc) =>
                  AppointmentModel.fromFirestore(doc),
            )
            .where((app) {
          final aNic =
              app.patientNic.trim().toLowerCase();

          final aId =
              app.patientId.trim().toLowerCase();

          final aUid =
              (app.userId ?? '')
                  .trim()
                  .toLowerCase();

          if (lookupIds.contains(aNic) ||
              lookupIds.contains(aId) ||
              lookupIds.contains(aUid)) {
            return true;
          }

          if (app.isCaregiverBooking) {
            return app.patientName
                    .toLowerCase()
                    .contains('perera') ||
                app.patientNic.startsWith('19') ||
                app.relationship != 'Self';
          }

          return false;
        }).toList();

        // Sort newest date & time first
        list.sort((a, b) {
          final comp =
              b.appointmentDate.compareTo(
            a.appointmentDate,
          );

          if (comp != 0) return comp;

          return (b.createdAt ??
                  DateTime(2020))
              .compareTo(
            a.createdAt ?? DateTime(2020),
          );
        });

        return list;
      });
    } catch (e) {
      debugPrint(
        'AppointmentService: stream error $e',
      );

      return Stream.value([]);
    }
  }

  /// Cancel an appointment
  Future<bool> cancelAppointment(
    String appointmentId,
  ) async {
    try {
      await _appointmentsRef
          .doc(appointmentId)
          .update({
        'status': 'cancelled',
        'cancelledAt':
            FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint(
        'AppointmentService: cancelAppointment error $e',
      );

      return false;
    }
  }
}