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
      final hId = (hospitalId == 'HOSP-001') ? 'nhsl' : hospitalId;
      final dId = (departmentId == 'DEPT-001') ? 'gen_med' : departmentId;

      final snapshot = await _db
          .collection(AppConstants.appointmentsCollection)
          .where('appointmentDate', isEqualTo: dateStr)
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((apt) =>
              (apt.hospitalId == hId || apt.hospitalId == 'HOSP-001' || hId.isEmpty) &&
              (apt.departmentId == dId || apt.departmentId == 'DEPT-001' || dId.isEmpty))
          .toList();
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
    final hId = (hospitalId == 'HOSP-001') ? 'nhsl' : hospitalId;
    return _db
        .collection(AppConstants.queueSessionsCollection)
        .where('hospitalId', isEqualTo: hId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QueueSession.fromFirestore(doc)).toList());
  }

  Future<QueueSession?> getQueueSession(String sessionId) async {
    final doc = await _db.collection(AppConstants.queueSessionsCollection).doc(sessionId).get();
    return doc.exists ? QueueSession.fromFirestore(doc) : null;
  }

  // --- Dual-Collection Merged Queue Stream with Zero Date Restrictions ---
  Stream<List<QueueEntry>> streamPatientQueue(String sessionId, {String? hospitalId, String? departmentId}) {
    String reqHosp = hospitalId ?? '';
    String reqDept = departmentId ?? '';

    if ((reqHosp.isEmpty || reqDept.isEmpty) && sessionId.contains('_')) {
      final parts = sessionId.split('_');
      if (parts.length >= 2) {
        if (reqHosp.isEmpty) reqHosp = parts[0];
        if (reqDept.isEmpty) reqDept = parts[1];
      }
    }

    final normalizedHosp = (reqHosp == 'HOSP-001') ? 'nhsl' : reqHosp;
    final normalizedDept = (reqDept == 'DEPT-001') ? 'gen_med' : reqDept;

    final targetH = normalizedHosp.toLowerCase();
    final targetD = normalizedDept.toLowerCase();

    // Stream both queue_entries and appointments in real-time without date restrictions!
    return _db.collection(AppConstants.appointmentsCollection).snapshots().asyncMap((aptSnapshot) async {
      List<QueueEntry> entries = [];
      Set<String> processedAptIds = {};

      // 1. Fetch queue_entries to get latest status if any
      final qeSnapshot = await _db.collection(AppConstants.queueEntriesCollection).get();
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> qeByAptId = {};
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> qeById = {};

      for (var qeDoc in qeSnapshot.docs) {
        final data = qeDoc.data();
        qeById[qeDoc.id] = qeDoc;
        final aptId = (data['appointmentId'] ?? '').toString();
        if (aptId.isNotEmpty) {
          qeByAptId[aptId] = qeDoc;
        }
      }

      // 2. Process all appointments matching hospital & clinic (NO DATE RULES)
      for (var aptDoc in aptSnapshot.docs) {
        final aptData = aptDoc.data();
        final aptId = aptDoc.id;

        final rawAptH = (aptData['hospitalId'] ?? '').toString().toLowerCase();
        final rawAptD = (aptData['departmentId'] ?? aptData['clinicId'] ?? '').toString().toLowerCase();
        final aptH = (rawAptH == 'hosp-001' || rawAptH.isEmpty) ? 'nhsl' : rawAptH;

        String aptD = rawAptD;
        if (aptD == 'dept-001' || aptD.contains('gen_med')) aptD = 'gen_med';
        else if (aptD.contains('ortho')) aptD = 'ortho';
        else if (aptD.contains('ent')) aptD = 'ent';
        else if (aptD.contains('derma')) aptD = 'derma';
        else if (aptD.contains('pedia')) aptD = 'pedia';

        final hospMatches = targetH.isEmpty || targetH == 'all' || aptH.isEmpty || aptH == targetH || targetH.contains(aptH) || aptH.contains(targetH);

        bool deptMatches = false;
        if (targetD.isEmpty || targetD == 'all') {
          deptMatches = true; // Show EVERY clinic when All OPD Clinics is selected!
        } else if (targetD == 'gen_med') {
          deptMatches = aptD == 'gen_med' || aptD.contains('gen');
        } else if (targetD == 'ortho') {
          deptMatches = aptD == 'ortho';
        } else if (targetD == 'ent' || targetD == 'dept_ent') {
          deptMatches = aptD == 'ent' || aptD == 'dept_ent';
        } else if (targetD == 'derma') {
          deptMatches = aptD == 'derma';
        } else if (targetD == 'pedia' || targetD == 'dept_pediatrics') {
          deptMatches = aptD == 'pedia' || aptD == 'dept_pediatrics';
        } else {
          deptMatches = aptD == targetD;
        }

        // When staff is viewing "All OPD Clinics", show ALL appointments across hospitals & clinics!
        final shouldInclude = (targetD == 'all') ? true : (hospMatches && deptMatches);

        if (shouldInclude) {
          processedAptIds.add(aptId);

          // Check if queue_entry has an updated status (e.g., called, on_hold, completed)
          final qeDoc = qeByAptId[aptId] ?? qeById[aptId];
          final qeData = qeDoc?.data();

          final statusStr = (qeData?['status'] ?? aptData['status'] ?? 'waiting').toString().toLowerCase();
          final effectiveStatus = statusStr == 'called'
              ? 'called'
              : (statusStr == 'completed'
                  ? 'completed'
                  : (statusStr == 'on_hold'
                      ? 'on_hold'
                      : (statusStr == 'missed' ? 'missed' : 'waiting')));

          String patientName = (qeData?['patientName'] ?? aptData['patientName'] ?? '').toString();
          final patientId = (qeData?['patientId'] ?? aptData['patientId'] ?? '').toString();

          if (patientName.isEmpty || patientName == 'Patient' || patientName == 'Unknown Patient') {
            if (patientId.isNotEmpty) {
              try {
                final userDoc = await _db.collection(AppConstants.usersCollection).doc(patientId).get();
                if (userDoc.exists && userDoc.data() != null) {
                  patientName = userDoc.data()!['fullName'] ?? 'Patient';
                }
              } catch (_) {}
            }
          }
          if (patientName.isEmpty) patientName = 'Patient';

          final token = (qeData?['tokenNumber'] ?? qeData?['tokenCode'] ?? aptData['tokenNumber'] ?? aptData['tokenCode'] ?? 'A-${entries.length + 1}').toString();

          entries.add(QueueEntry(
            queueEntryId: qeDoc?.id ?? aptId,
            queueSessionId: sessionId,
            appointmentId: aptId,
            patientId: patientId,
            tokenNumber: token,
            tokenCode: token,
            status: effectiveStatus,
            queuePosition: entries.length + 1,
            estimatedWaitMinutes: entries.length * 10,
            priority: (qeData?['priority'] ?? aptData['priority'] ?? 'normal').toString(),
            patientName: patientName,
          ));
        }
      }

      // 3. Also include any loose queue_entries not matched in appointments
      for (var qeDoc in qeSnapshot.docs) {
        final qeData = qeDoc.data();
        final aptId = (qeData['appointmentId'] ?? '').toString();
        if (processedAptIds.contains(aptId) || processedAptIds.contains(qeDoc.id)) {
          continue;
        }

        final rawH = (qeData['hospitalId'] ?? '').toString().toLowerCase();
        final rawD = (qeData['departmentId'] ?? '').toString().toLowerCase();
        final qeH = (rawH == 'hosp-001' || rawH.isEmpty) ? 'nhsl' : rawH;

        String qeD = rawD;
        if (qeD == 'dept-001' || qeD.contains('gen_med')) qeD = 'gen_med';
        else if (qeD.contains('ortho')) qeD = 'ortho';
        else if (qeD.contains('ent')) qeD = 'ent';
        else if (qeD.contains('derma')) qeD = 'derma';
        else if (qeD.contains('pedia')) qeD = 'pedia';

        final hospMatches = qeH.isEmpty || targetH.isEmpty || qeH == targetH || targetH.contains(qeH) || qeH.contains(targetH);
        final deptMatches = targetD.isEmpty || targetD == 'all' || qeD == targetD;

        if (hospMatches && deptMatches) {
          final entry = QueueEntry.fromFirestore(qeDoc);
          entries.add(entry);
        }
      }

      // Accurate Queue Sorting: Emergency Priority -> Queue Position -> Numerical Token Number
      entries.sort((a, b) {
        if (a.priority == AppConstants.priorityEmergency && b.priority != AppConstants.priorityEmergency) {
          return -1;
        } else if (a.priority != AppConstants.priorityEmergency && b.priority == AppConstants.priorityEmergency) {
          return 1;
        }
        final posComp = a.queuePosition.compareTo(b.queuePosition);
        if (posComp != 0) return posComp;
        return _parseTokenNumber(a.tokenNumber).compareTo(_parseTokenNumber(b.tokenNumber));
      });

      return entries;
    });
  }

  static int _parseTokenNumber(String token) {
    final regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(token);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 999;
    }
    return 999;
  }

  Stream<List<QueueEntry>> streamQueueEntries(String sessionId) {
    return streamPatientQueue(sessionId);
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
      if (doc.exists) {
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
      }

      final rawId = queueEntryId.startsWith('QE-') ? queueEntryId.substring(3) : queueEntryId;
      if (rawId != queueEntryId) {
        final rawDoc = await _db.collection(AppConstants.queueEntriesCollection).doc(rawId).get();
        if (rawDoc.exists) {
          final data = rawDoc.data() ?? {};
          String patientName = data['patientName'] ?? '';
          if (patientName.isEmpty && data['patientId'] != null) {
            try {
              final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
              if (userDoc.exists && userDoc.data() != null) {
                patientName = userDoc.data()!['fullName'] ?? 'Patient';
              }
            } catch (_) {}
          }
          return QueueEntry.fromFirestore(rawDoc, patientName: patientName);
        }
      }

      // Check appointments collection
      final aptDoc = await _db.collection(AppConstants.appointmentsCollection).doc(rawId).get();
      if (aptDoc.exists) {
        final data = aptDoc.data() ?? {};
        final token = (data['tokenNumber'] ?? data['tokenCode'] ?? 'A-001').toString();
        String patientName = (data['patientName'] ?? '').toString();
        if (patientName.isEmpty && data['patientId'] != null) {
          try {
            final userDoc = await _db.collection(AppConstants.usersCollection).doc(data['patientId']).get();
            if (userDoc.exists && userDoc.data() != null) {
              patientName = userDoc.data()!['fullName'] ?? 'Patient';
            }
          } catch (_) {}
        }
        return QueueEntry(
          queueEntryId: rawId,
          queueSessionId: (data['queueSessionId'] ?? AppConstants.defaultQueueSessionId()).toString(),
          appointmentId: rawId,
          patientId: (data['patientId'] ?? '').toString(),
          tokenNumber: token,
          tokenCode: token,
          status: (data['status'] ?? 'waiting').toString(),
          queuePosition: 1,
          estimatedWaitMinutes: 5,
          priority: (data['priority'] ?? 'normal').toString(),
          patientName: patientName.isNotEmpty ? patientName : 'Patient',
        );
      }

      return _getMockQueueEntry(queueEntryId);
    } catch (_) {
      return _getMockQueueEntry(queueEntryId);
    }
  }

  QueueEntry _getMockQueueEntry(String queueEntryId) {
    return QueueEntry(
      queueEntryId: queueEntryId,
      queueSessionId: AppConstants.defaultQueueSessionId(),
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
