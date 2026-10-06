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
    return _db
        .collection(AppConstants.queueEntriesCollection)
        .where('queueSessionId', isEqualTo: sessionId)
        .snapshots()
        .asyncMap((snapshot) async {
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

      // If empty for this exact sessionId, check appointments collection
      if (entries.isEmpty) {
        try {
          final parts = sessionId.split('_');
          final dept = parts.length >= 2 ? parts[1] : 'gen_med';
          final apptsSnap = await _db
              .collection(AppConstants.appointmentsCollection)
              .where('departmentId', isEqualTo: dept)
              .get();

          for (var aDoc in apptsSnap.docs) {
            final aData = aDoc.data();
            final token = (aData['tokenCode'] ?? 'A-001').toString();
            entries.add(QueueEntry(
              queueEntryId: aDoc.id,
              queueSessionId: sessionId,
              appointmentId: aDoc.id,
              patientId: (aData['patientId'] ?? '').toString(),
              tokenNumber: token,
              tokenCode: token,
              status: (aData['status'] ?? 'waiting').toString(),
              patientName: (aData['patientName'] ?? 'Patient $token').toString(),
              queuePosition: 1,
            ));
          }
        } catch (_) {}
      }

      // Sort by position or emergency priority
      entries.sort((a, b) {
        if (a.priority == AppConstants.priorityEmergency && b.priority != AppConstants.priorityEmergency) {
          return -1;
        } else if (a.priority != AppConstants.priorityEmergency && b.priority == AppConstants.priorityEmergency) {
          return 1;
        }
        return a.queuePosition.compareTo(b.queuePosition);
      });

      return entries;
    });
  }

  Future<List<QueueEntry>> getPatientQueue(String sessionId) async {
    final snapshot = await _db
        .collection(AppConstants.queueEntriesCollection)
        .where('queueSessionId', isEqualTo: sessionId)
        .get();

    List<QueueEntry> entries = [];
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
      entries.add(QueueEntry.fromFirestore(doc, patientName: patientName.isNotEmpty ? patientName : null));
    }
    return entries;
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
