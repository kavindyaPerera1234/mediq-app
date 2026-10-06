import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/staff_profile.dart';
import '../models/queue_session.dart';
import '../models/queue_entry.dart';
import '../models/delay_update.dart';
import '../models/notification_model.dart';
import '../models/appointment.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users & Staff Profiles ---
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  Future<StaffProfile?> getStaffProfile(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.staffProfilesCollection).doc(uid).get();
      if (doc.exists) {
        return StaffProfile.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  // --- Appointments ---
  Future<List<Appointment>> getTodayAppointments(String hospitalId, String departmentId, String dateStr) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.appointmentsCollection)
          .where('hospitalId', isEqualTo: hospitalId)
          .where('departmentId', isEqualTo: departmentId)
          .where('appointmentDate', isEqualTo: dateStr)
          .get();

      return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Appointment?> getAppointment(String appointmentId) async {
    final doc = await _db.collection(AppConstants.appointmentsCollection).doc(appointmentId).get();
    return doc.exists ? Appointment.fromFirestore(doc) : null;
  }

  // --- Queue Sessions ---
  Stream<QueueSession?> streamQueueSession(String sessionId) {
    return _db
        .collection(AppConstants.queueSessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? QueueSession.fromFirestore(doc) : null);
  }

  Stream<List<QueueSession>> streamHospitalSessions(String hospitalId) {
    return _db
        .collection(AppConstants.queueSessionsCollection)
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QueueSession.fromFirestore(doc)).toList());
  }

  Future<QueueSession?> getQueueSession(String sessionId) async {
    final doc = await _db.collection(AppConstants.queueSessionsCollection).doc(sessionId).get();
    return doc.exists ? QueueSession.fromFirestore(doc) : null;
  }

  // --- Queue Entries ---
  Stream<List<QueueEntry>> streamQueueEntries(String sessionId) {
    late StreamController<List<QueueEntry>> controller;
    StreamSubscription? qSub;
    StreamSubscription? aSub;

    final parts = sessionId.split('_');
    final dept = parts.length >= 2 ? parts[1] : 'gen_med';
    final dateStr = parts.length >= 3 ? parts[2] : '';

    List<QueueEntry> queueEntries = [];
    List<QueueEntry> apptEntries = [];

    void emitMerged() {
      if (controller.isClosed) return;
      final Map<String, QueueEntry> merged = {};

      // 1. Add queue_entries
      for (var qe in queueEntries) {
        final key = qe.appointmentId.isNotEmpty ? qe.appointmentId : qe.queueEntryId;
        merged[key] = qe;
      }

      // 2. Add appointments (newly booked OPD patients)
      for (var appt in apptEntries) {
        final key = appt.appointmentId.isNotEmpty ? appt.appointmentId : appt.queueEntryId;
        if (!merged.containsKey(key)) {
          merged[key] = appt;
        } else {
          // If queue_entry has default placeholder name, upgrade with appointment's real patientName
          final existing = merged[key]!;
          if ((existing.patientName == null || existing.patientName == 'Patient' || existing.patientName == 'Unknown Patient') &&
              (appt.patientName != null && appt.patientName!.isNotEmpty && appt.patientName != 'Patient')) {
            merged[key] = QueueEntry(
              queueEntryId: existing.queueEntryId,
              queueSessionId: existing.queueSessionId,
              appointmentId: existing.appointmentId,
              patientId: existing.patientId,
              tokenNumber: existing.tokenNumber,
              tokenCode: existing.tokenCode,
              status: existing.status,
              queuePosition: existing.queuePosition,
              estimatedWaitMinutes: existing.estimatedWaitMinutes,
              priority: existing.priority,
              calledAt: existing.calledAt,
              consultationStartedAt: existing.consultationStartedAt,
              completedAt: existing.completedAt,
              missedAt: existing.missedAt,
              createdAt: existing.createdAt,
              updatedAt: existing.updatedAt,
              patientName: appt.patientName,
            );
          }
        }
      }

      final list = merged.values.toList();
      // Sort: Emergency priority first, then position / token
      list.sort((a, b) {
        if (a.priority == AppConstants.priorityEmergency && b.priority != AppConstants.priorityEmergency) {
          return -1;
        } else if (a.priority != AppConstants.priorityEmergency && b.priority == AppConstants.priorityEmergency) {
          return 1;
        }
        final posComp = a.queuePosition.compareTo(b.queuePosition);
        if (posComp != 0) return posComp;
        return a.tokenNumber.compareTo(b.tokenNumber);
      });

      controller.add(list);
    }

    controller = StreamController<List<QueueEntry>>.broadcast(
      onListen: () {
        // Listen to queue_entries collection
        qSub = _db
            .collection(AppConstants.queueEntriesCollection)
            .where('queueSessionId', isEqualTo: sessionId)
            .snapshots()
            .listen((snapshot) async {
          List<QueueEntry> entries = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            String patientName = (data['patientName'] ?? '').toString();
            if ((patientName.isEmpty || patientName == 'Unknown Patient') && data['patientId'] != null) {
              try {
                final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
                if (userDoc.exists && userDoc.data() != null) {
                  patientName = (userDoc.data()!['fullName'] ?? patientName).toString();
                }
              } catch (_) {}
            }
            entries.add(QueueEntry.fromFirestore(doc, patientName: patientName.isNotEmpty ? patientName : null));
          }
          queueEntries = entries;
          emitMerged();
        }, onError: (err) {
          debugPrint('queue_entries stream error: $err');
        });

        // Listen to appointments collection in real-time
        var apptQuery = _db
            .collection(AppConstants.appointmentsCollection)
            .where('departmentId', isEqualTo: dept);
        if (dateStr.isNotEmpty) {
          apptQuery = apptQuery.where('appointmentDate', isEqualTo: dateStr);
        }

        aSub = apptQuery.snapshots().listen((snapshot) {
          List<QueueEntry> list = [];
          for (var aDoc in snapshot.docs) {
            final aData = aDoc.data();
            final token = (aData['tokenCode'] ?? aData['tokenNumber'] ?? 'A-001').toString();
            final rawStatus = (aData['status'] ?? 'waiting').toString();
            final mappedStatus = (rawStatus == 'confirmed' || rawStatus == 'booked') ? 'waiting' : rawStatus;
            final pName = (aData['patientName'] ?? 'Patient $token').toString();
            final priority = (aData['priority'] ?? 'normal').toString();
            list.add(QueueEntry(
              queueEntryId: aDoc.id,
              queueSessionId: sessionId,
              appointmentId: aDoc.id,
              patientId: (aData['patientId'] ?? '').toString(),
              tokenNumber: token,
              tokenCode: token,
              status: mappedStatus,
              patientName: pName,
              priority: priority,
              queuePosition: 1,
            ));
          }
          apptEntries = list;
          emitMerged();
        }, onError: (err) {
          debugPrint('appointments stream error: $err');
        });
      },
      onCancel: () {
        qSub?.cancel();
        aSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<List<QueueEntry>> getPatientQueue(String sessionId) async {
    final parts = sessionId.split('_');
    final dept = parts.length >= 2 ? parts[1] : 'gen_med';
    final dateStr = parts.length >= 3 ? parts[2] : '';

    final Map<String, QueueEntry> merged = {};

    try {
      final snapshot = await _db
          .collection(AppConstants.queueEntriesCollection)
          .where('queueSessionId', isEqualTo: sessionId)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String patientName = (data['patientName'] ?? '').toString();
        if (patientName.isEmpty && data['patientId'] != null) {
          try {
            final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
            if (userDoc.exists && userDoc.data() != null) {
              patientName = (userDoc.data()!['fullName'] ?? 'Patient').toString();
            }
          } catch (_) {}
        }
        final entry = QueueEntry.fromFirestore(doc, patientName: patientName.isNotEmpty ? patientName : null);
        merged[entry.appointmentId.isNotEmpty ? entry.appointmentId : entry.queueEntryId] = entry;
      }
    } catch (_) {}

    try {
      var apptQuery = _db.collection(AppConstants.appointmentsCollection).where('departmentId', isEqualTo: dept);
      if (dateStr.isNotEmpty) {
        apptQuery = apptQuery.where('appointmentDate', isEqualTo: dateStr);
      }
      final apptsSnap = await apptQuery.get();
      for (var aDoc in apptsSnap.docs) {
        final key = aDoc.id;
        if (!merged.containsKey(key)) {
          final aData = aDoc.data();
          final token = (aData['tokenCode'] ?? aData['tokenNumber'] ?? 'A-001').toString();
          final rawStatus = (aData['status'] ?? 'waiting').toString();
          final mappedStatus = (rawStatus == 'confirmed' || rawStatus == 'booked') ? 'waiting' : rawStatus;
          merged[key] = QueueEntry(
            queueEntryId: aDoc.id,
            queueSessionId: sessionId,
            appointmentId: aDoc.id,
            patientId: (aData['patientId'] ?? '').toString(),
            tokenNumber: token,
            tokenCode: token,
            status: mappedStatus,
            patientName: (aData['patientName'] ?? 'Patient $token').toString(),
            priority: (aData['priority'] ?? 'normal').toString(),
            queuePosition: merged.length + 1,
          );
        }
      }
    } catch (_) {}

    final list = merged.values.toList();
    list.sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
    return list;
  }

  Future<QueueEntry?> getQueueEntry(String queueEntryId) async {
    return getPatientDetails(queueEntryId);
  }

  Future<QueueEntry?> getPatientDetails(String queueEntryId) async {
    try {
      final doc = await _db.collection(AppConstants.queueEntriesCollection).doc(queueEntryId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        String patientName = (data['patientName'] ?? '').toString();
        if (patientName.isEmpty && data['patientId'] != null) {
          try {
            final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
            if (userDoc.exists && userDoc.data() != null) {
              patientName = (userDoc.data()!['fullName'] ?? 'Patient').toString();
            }
          } catch (_) {}
        }
        return QueueEntry.fromFirestore(doc, patientName: patientName.isNotEmpty ? patientName : null);
      }

      // Try checking appointments collection
      final apptDoc = await _db.collection(AppConstants.appointmentsCollection).doc(queueEntryId).get();
      if (apptDoc.exists) {
        final aData = apptDoc.data() ?? {};
        final token = (aData['tokenCode'] ?? 'A-001').toString();
        return QueueEntry(
          queueEntryId: apptDoc.id,
          queueSessionId: AppConstants.defaultQueueSessionId(),
          appointmentId: apptDoc.id,
          patientId: (aData['patientId'] ?? '').toString(),
          tokenNumber: token,
          tokenCode: token,
          status: (aData['status'] ?? 'waiting').toString(),
          patientName: (aData['patientName'] ?? 'Patient').toString(),
          priority: (aData['priority'] ?? 'normal').toString(),
          queuePosition: 1,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // --- Delay Updates ---
  Stream<List<DelayUpdate>> streamDelayUpdates(String sessionId) {
    return _db
        .collection(AppConstants.delayUpdatesCollection)
        .where('queueSessionId', isEqualTo: sessionId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DelayUpdate.fromFirestore(doc)).toList());
  }

  // --- Notifications Stream ---
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }
}
