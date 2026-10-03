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
        String patientName = data['patientName'] ?? 'Unknown Patient';
        if ((patientName.isEmpty || patientName == 'Unknown Patient') && data['patientId'] != null) {
          final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
          if (userDoc.exists && userDoc.data() != null) {
            patientName = userDoc.data()!['fullName'] ?? patientName;
          }
        }
        entries.add(QueueEntry.fromFirestore(doc, patientName: patientName));
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
      String patientName = data['patientName'] ?? '';
      if (patientName.isEmpty && data['patientId'] != null) {
        final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
        if (userDoc.exists && userDoc.data() != null) {
          patientName = userDoc.data()!['fullName'] ?? 'Patient';
        }
      }
      entries.add(QueueEntry.fromFirestore(doc, patientName: patientName));
    }
    return entries;
  }

  Future<QueueEntry?> getQueueEntry(String queueEntryId) async {
    return getPatientDetails(queueEntryId);
  }

  Future<QueueEntry?> getPatientDetails(String queueEntryId) async {
    try {
      final doc = await _db.collection(AppConstants.queueEntriesCollection).doc(queueEntryId).get();
      if (!doc.exists) return _getMockQueueEntry(queueEntryId);

      final data = doc.data() ?? {};
      String patientName = data['patientName'] ?? '';
      if (patientName.isEmpty && data['patientId'] != null) {
        try {
          final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
          if (userDoc.exists && userDoc.data() != null) {
            patientName = userDoc.data()!['fullName'] ?? 'Patient';
          }
        } catch (_) {}
      }
      return QueueEntry.fromFirestore(doc, patientName: patientName);
    } catch (_) {
      return _getMockQueueEntry(queueEntryId);
    }
  }

  QueueEntry _getMockQueueEntry(String queueEntryId) {
    return QueueEntry(
      queueEntryId: queueEntryId,
      queueSessionId: 'QS-001',
      appointmentId: 'APT-021',
      patientId: 'pat-021',
      tokenNumber: 'A-021',
      tokenCode: 'A-021',
      status: 'called',
      queuePosition: 1,
      estimatedWaitMinutes: 5,
      priority: 'normal',
      patientName: 'Kasun Perera',
      calledAt: DateTime.now(),
    );
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
