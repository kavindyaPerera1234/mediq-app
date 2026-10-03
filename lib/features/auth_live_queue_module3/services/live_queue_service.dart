import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_session_model.dart';
import '../models/queue_entry_model.dart';
import 'auth_service.dart';

/// Module 3 — Live Queue Service (real-time, cross-module).
///
/// Shared Firestore contract (full details in `QUEUE_CONTRACT.md`):
///
/// • READS  `appointments`        → written by Module 1 (booking) and
///                                  Module 2 (reschedule / cancel).
/// • READS  `queue_sessions/{hospitalId}_{departmentId}_{yyyy-MM-dd}`
///                                → clinic state written by Module 4 (doctor):
///                                  doctorName, delayMinutes, delayReason,
///                                  estimatedMinutesPerPatient, status.
/// • WRITES the patient's own appointment when they rejoin the queue.
/// • WRITES `notifications`       → queue alerts for Module 2's Notification Centre.
///
class LiveQueueService extends ChangeNotifier {
  static final LiveQueueService _instance = LiveQueueService._internal();
  factory LiveQueueService() => _instance;
  LiveQueueService._internal() {
    _initFallbackState();
    start();
  }

  /// Shared demo patient NIC used by Module 1 & 2 until real patient auth exists.
  static const String demoPatientNic = '200164801234';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _mySub;
  StreamSubscription? _queueSub;
  StreamSubscription? _sessionSub;
  String? _watchedDepartment;
  String? _watchedSessionId;

  bool _started = false;
  bool _isLoading = true;
  String? _error;

  String? _myApptId;
  Map<String, dynamic>? _myAppt;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _deptDocs = [];
  Map<String, dynamic>? _sessionDoc;

  QueueSessionModel? _session;
  QueueEntryModel? _entry;
  List<QueueEntryModel> _queue = [];

  // Change tracking for alerts / auto-navigation
  final _statusController = StreamController<PatientQueueStatus>.broadcast();
  PatientQueueStatus? _lastStatus;
  bool _lastDelayed = false;
  String? _trackedApptId;

  // ── Public getters ────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveAppointment => _entry != null;

  QueueSessionModel get session => _session ?? _emptySession();
  QueueEntryModel get myEntry => _entry ?? _emptyEntry();

  /// Full ordered queue for the patient's clinic session (used by Timeline).
  List<QueueEntryModel> get queue => List.unmodifiable(_queue);

  /// Fires whenever the patient's queue status changes (called, missed, …).
  Stream<PatientQueueStatus> get statusChanges => _statusController.stream;

  String get appointmentDate => (_myAppt?['appointmentDate'] ?? '').toString();
  String get appointmentTimeSlot => (_myAppt?['timeSlot'] ?? '').toString();
  bool get isToday => appointmentDate == _todayString();

  String get currentPatientNic {
    final nic = AuthService().currentUser?.nic;
    return (nic != null && nic.trim().isNotEmpty) ? nic.trim() : demoPatientNic;
  }

  // ── Spec Stream & Query Methods ──────────────────────────────────────────

  /// Stream a specific queue entry by ID (from queue_entries or appointments)
  Stream<QueueEntryModel?> watchQueueEntry(String queueEntryId) {
    return _firestore
        .collection('queue_entries')
        .doc(queueEntryId)
        .snapshots()
        .asyncMap((doc) async {
      if (doc.exists && doc.data() != null) {
        return QueueEntryModel.fromMap(doc.data()!, id: doc.id);
      }
      final apptDoc = await _firestore.collection('appointments').doc(queueEntryId).get();
      if (apptDoc.exists && apptDoc.data() != null) {
        final d = apptDoc.data()!;
        return QueueEntryModel(
          queueEntryId: apptDoc.id,
          appointmentId: apptDoc.id,
          patientId: (d['patientId'] ?? d['patientNic'] ?? '').toString(),
          patientName: (d['patientName'] ?? 'Patient').toString(),
          tokenCode: (d['tokenCode'] ?? '—').toString(),
          queuePosition: 1,
          peopleAhead: 0,
          status: _mapStatus(_statusOf(d)),
          estimatedWaitMinutes: 0,
          joinedAt: _toDate(d['createdAt']) ?? DateTime.now(),
        );
      }
      return null;
    });
  }

  /// Stream a specific queue session by ID
  Stream<QueueSessionModel?> watchQueueSession(String queueSessionId) {
    return _firestore
        .collection('queue_sessions')
        .doc(queueSessionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return QueueSessionModel.fromMap(doc.data()!, id: doc.id);
    });
  }

  /// Stream all queue entries for a given session ID
  Stream<List<QueueEntryModel>> watchQueueEntriesForSession(String queueSessionId) {
    return _firestore
        .collection('queue_entries')
        .where('queueSessionId', isEqualTo: queueSessionId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => QueueEntryModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
      return list;
    });
  }

  /// Get the queue entry for an appointment
  Future<QueueEntryModel?> getQueueEntryForAppointment(String appointmentId) async {
    final snap = await _firestore
        .collection('queue_entries')
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return QueueEntryModel.fromMap(snap.docs.first.data(), id: snap.docs.first.id);
    }

    final apptDoc = await _firestore.collection('appointments').doc(appointmentId).get();
    if (apptDoc.exists && apptDoc.data() != null) {
      final d = apptDoc.data()!;
      return QueueEntryModel(
        queueEntryId: apptDoc.id,
        appointmentId: apptDoc.id,
        patientId: (d['patientId'] ?? d['patientNic'] ?? '').toString(),
        patientName: (d['patientName'] ?? 'Patient').toString(),
        tokenCode: (d['tokenCode'] ?? '—').toString(),
        queuePosition: 1,
        peopleAhead: 0,
        status: _mapStatus(_statusOf(d)),
        estimatedWaitMinutes: 0,
        joinedAt: _toDate(d['createdAt']) ?? DateTime.now(),
      );
    }
    return null;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Starts real-time listening. Safe to call many times.
  void start() {
    if (_started) return;
    _started = true;
    _isLoading = true;
    _error = null;

    _mySub = _firestore
        .collection('appointments')
        .where('patientNic', isEqualTo: currentPatientNic)
        .snapshots()
        .listen(_onMyAppointments, onError: _onStreamError);
  }

  /// Tears down and restarts all listeners (e.g. after login change).
  void refresh() {
    _cancelAll();
    _started = false;
    _watchedDepartment = null;
    _watchedSessionId = null;
    start();
    notifyListeners();
  }

  void _cancelAll() {
    _mySub?.cancel();
    _queueSub?.cancel();
    _sessionSub?.cancel();
    _mySub = _queueSub = _sessionSub = null;
  }

  void _onStreamError(Object e) {
    debugPrint('LiveQueueService stream error: $e');
    _error = 'Could not connect to the live queue. Check your connection.';
    _isLoading = false;
    notifyListeners();
  }

  // ── Stream handlers ───────────────────────────────────────────────────────

  void _onMyAppointments(QuerySnapshot<Map<String, dynamic>> snap) {
    final today = _todayString();
    final active = snap.docs.where((d) => _statusOf(d.data()) != 'cancelled').toList();

    QueryDocumentSnapshot<Map<String, dynamic>>? pick;

    // 1. Today's appointment — prefer one still in progress.
    final todays = active.where((d) => d.data()['appointmentDate'] == today).toList();
    if (todays.isNotEmpty) {
      todays.sort((a, b) => _orderOf(a.data()).compareTo(_orderOf(b.data())));
      pick = todays.firstWhere(
        (d) => !_isFinished(_statusOf(d.data())),
        orElse: () => todays.last,
      );
    } else {
      // 2. Otherwise the next upcoming appointment.
      final upcoming = active.where((d) {
        final date = (d.data()['appointmentDate'] ?? '').toString();
        return date.compareTo(today) > 0 && !_isFinished(_statusOf(d.data()));
      }).toList()
        ..sort((a, b) {
          final c = (a.data()['appointmentDate'] ?? '')
              .toString()
              .compareTo((b.data()['appointmentDate'] ?? '').toString());
          return c != 0
              ? c
              : (a.data()['timeSlot'] ?? '').toString().compareTo((b.data()['timeSlot'] ?? '').toString());
        });
      if (upcoming.isNotEmpty) pick = upcoming.first;
    }

    if (pick == null) {
      _myAppt = null;
      _myApptId = null;
      _queueSub?.cancel();
      _sessionSub?.cancel();
      _watchedDepartment = null;
      _watchedSessionId = null;
      _deptDocs = [];
      _sessionDoc = null;
      _isLoading = false;
      _error = null;
      _recompute();
      return;
    }

    _myApptId = pick.id;
    _myAppt = pick.data();
    _error = null;

    final hospitalId = (_myAppt!['hospitalId'] ?? '').toString();
    final departmentId = (_myAppt!['departmentId'] ?? '').toString();
    final date = (_myAppt!['appointmentDate'] ?? '').toString();

    // Everyone booked into the same clinic (filtered by date/hospital client-side
    // so no composite Firestore index is required).
    if (_watchedDepartment != departmentId) {
      _watchedDepartment = departmentId;
      _queueSub?.cancel();
      _queueSub = _firestore
          .collection('appointments')
          .where('departmentId', isEqualTo: departmentId)
          .snapshots()
          .listen((s) {
        _deptDocs = s.docs;
        _isLoading = false;
        _recompute();
      }, onError: _onStreamError);
    }

    // Clinic session state from Module 4 (doctor / delays / pace).
    final sessionId = sessionIdFor(hospitalId, departmentId, date);
    if (_watchedSessionId != sessionId) {
      _watchedSessionId = sessionId;
      _sessionDoc = null;
      _sessionSub?.cancel();
      _sessionSub = _firestore.collection('queue_sessions').doc(sessionId).snapshots().listen((s) {
        _sessionDoc = s.data();
        _recompute();
      }, onError: (e) => debugPrint('queue_sessions stream notice: $e'));
    }

    _recompute();
  }

  // ── Core queue calculation ────────────────────────────────────────────────

  void _recompute() {
    if (_myAppt == null || _myApptId == null) {
      _initFallbackState();
      _queue = [];
      _lastStatus = null;
      _trackedApptId = null;
      notifyListeners();
      return;
    }

    final me = _myAppt!;
    final date = (me['appointmentDate'] ?? '').toString();
    final hospitalId = (me['hospitalId'] ?? '').toString();

    // Same clinic + same day, excluding cancelled.
    final docs = <String, Map<String, dynamic>>{};
    for (final d in _deptDocs) {
      final data = d.data();
      if ((data['appointmentDate'] ?? '').toString() != date) continue;
      if (hospitalId.isNotEmpty && (data['hospitalId'] ?? '').toString() != hospitalId) continue;
      if (_statusOf(data) == 'cancelled') continue;
      docs[d.id] = data;
    }
    docs[_myApptId!] = me; // always include my own (freshest copy)

    final ordered = docs.entries.toList()
      ..sort((a, b) {
        final c = _orderOf(a.value).compareTo(_orderOf(b.value));
        if (c != 0) return c;
        final ta = _toDate(a.value['createdAt']) ?? DateTime(2000);
        final tb = _toDate(b.value['createdAt']) ?? DateTime(2000);
        final t = ta.compareTo(tb);
        return t != 0 ? t : a.key.compareTo(b.key);
      });

    // Clinic session values (Module 4) with sensible defaults.
    final s = _sessionDoc ?? const <String, dynamic>{};
    final minsPerPatient = (s['estimatedMinutesPerPatient'] as num?)?.toInt() ?? 4;
    final delayMinutes = (s['delayMinutes'] as num?)?.toInt() ?? 0;
    final rawSessionStatus = (s['status'] ?? 'active').toString().toLowerCase();
    final isDelayed = delayMinutes > 0 || rawSessionStatus == 'delayed';

    // Now serving = whoever Module 4 called; otherwise next person not yet seen.
    final mapped = ordered.map((e) => _mapStatus(_statusOf(e.value))).toList();
    int servingIdx = mapped.indexWhere((st) => st == PatientQueueStatus.called);
    if (servingIdx < 0) servingIdx = mapped.indexWhere((st) => st == PatientQueueStatus.waiting);
    String nowServing = '—';
    if (servingIdx >= 0) {
      nowServing = (ordered[servingIdx].value['tokenCode'] ?? '—').toString();
    } else if (ordered.isNotEmpty) {
      final lastDone = mapped.lastIndexWhere((st) => st == PatientQueueStatus.completed);
      if (lastDone >= 0) nowServing = (ordered[lastDone].value['tokenCode'] ?? '—').toString();
    }

    // Build entries
    final entries = <QueueEntryModel>[];
    QueueEntryModel? mine;
    int stillWaitingAhead = 0;

    for (var i = 0; i < ordered.length; i++) {
      final id = ordered[i].key;
      final data = ordered[i].value;
      final base = mapped[i];
      final isMe = id == _myApptId;

      int ahead = 0;
      var status = base;
      int wait = 0;

      if (base == PatientQueueStatus.waiting) {
        ahead = stillWaitingAhead;
        if (isDelayed) {
          status = PatientQueueStatus.delayed;
        } else if (ahead <= 2) {
          status = PatientQueueStatus.approaching;
        }
        wait = ahead * minsPerPatient + delayMinutes;
      }

      final entry = QueueEntryModel(
        queueEntryId: id,
        appointmentId: id,
        patientId: (data['patientId'] ?? '').toString(),
        patientName: (data['patientName'] ?? 'Patient').toString(),
        tokenCode: (data['tokenCode'] ?? '—').toString(),
        queuePosition: i + 1,
        peopleAhead: ahead,
        status: status,
        estimatedWaitMinutes: wait < 0 ? 0 : wait,
        rejoinRequested: data['rejoinRequested'] == true,
        rejoinReason: data['rejoinReason']?.toString(),
        joinedAt: _toDate(data['createdAt']) ?? DateTime.now(),
        calledAt: _toDate(data['calledAt']),
      );
      entries.add(entry);
      if (isMe) mine = entry;

      if (base == PatientQueueStatus.waiting || base == PatientQueueStatus.called) {
        stillWaitingAhead++;
      }
    }

    QueueSessionStatus sessionStatus = QueueSessionStatus.active;
    if (isDelayed) {
      sessionStatus = QueueSessionStatus.delayed;
    } else if (rawSessionStatus == 'paused') {
      sessionStatus = QueueSessionStatus.paused;
    } else if (rawSessionStatus == 'completed') {
      sessionStatus = QueueSessionStatus.completed;
    }

    _session = QueueSessionModel(
      sessionId: sessionIdFor(hospitalId, (me['departmentId'] ?? '').toString(), date),
      hospitalId: hospitalId,
      hospitalName: (me['hospitalName'] ?? 'Hospital').toString(),
      departmentId: (me['departmentId'] ?? '').toString(),
      departmentName: (me['departmentName'] ?? 'OPD Clinic').toString(),
      roomNumber: (s['roomNumber'] ?? me['roomNumber'] ?? 'OPD Room 01').toString(),
      doctorName: (s['doctorName'] ?? 'Duty Medical Officer').toString(),
      currentTokenServing: nowServing,
      totalTokens: entries.length,
      estimatedMinutesPerPatient: minsPerPatient,
      status: sessionStatus,
      delayMinutes: delayMinutes,
      delayReason: s['delayReason']?.toString(),
      lastUpdated: _toDate(s['updatedAt']) ?? DateTime.now(),
    );
    _queue = entries;
    _entry = mine;

    _detectChanges(isDelayed);
    notifyListeners();
  }

  // ── Alerts: status-change events + Module 2 notifications ─────────────────

  void _detectChanges(bool isDelayed) {
    final entry = _entry;
    if (entry == null) return;

    // New appointment being tracked → set a baseline, don't fire alerts.
    if (_trackedApptId != entry.appointmentId) {
      _trackedApptId = entry.appointmentId;
      _lastStatus = entry.status;
      _lastDelayed = isDelayed;
      return;
    }

    if (entry.status != _lastStatus) {
      final prev = _lastStatus;
      _lastStatus = entry.status;
      _statusController.add(entry.status);

      switch (entry.status) {
        case PatientQueueStatus.approaching:
          if (prev == PatientQueueStatus.waiting || prev == PatientQueueStatus.delayed) {
            _pushNotification(
              type: 'near_turn',
              title: 'Your turn is near',
              message: 'Only ${entry.peopleAhead} patient(s) ahead of token ${entry.tokenCode}. '
                  'Please return to the waiting area near ${session.roomNumber}.',
            );
          }
          break;
        case PatientQueueStatus.called:
          _pushNotification(
            type: 'your_turn',
            title: "It's your turn!",
            message: 'Token ${entry.tokenCode}, please proceed to ${session.roomNumber} now.',
          );
          break;
        case PatientQueueStatus.missed:
          _pushNotification(
            type: 'missed_turn',
            title: 'You missed your turn',
            message: 'Token ${entry.tokenCode} was called but not present. You can rejoin the queue from the app.',
          );
          break;
        case PatientQueueStatus.completed:
          _pushNotification(
            type: 'consultation_completed',
            title: 'Consultation completed',
            message: 'Your consultation for token ${entry.tokenCode} is complete. Please collect medicine at the pharmacy.',
          );
          break;
        default:
          break;
      }
    }

    if (isDelayed && !_lastDelayed) {
      _pushNotification(
        type: 'queue_delay',
        title: 'OPD queue delayed',
        message: '${session.departmentName} is delayed by ${session.delayMinutes} minutes. '
            '${session.delayReason ?? ''}'.trim(),
        uniqueSuffix: '${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    _lastDelayed = isDelayed;
  }

  /// Writes a queue alert into the shared `notifications` collection using the
  /// same field names as Module 2's `NotificationModel.fromJson`.
  Future<void> _pushNotification({
    required String type,
    required String title,
    required String message,
    String? uniqueSuffix,
  }) async {
    final entry = _entry;
    if (entry == null) return;
    final id = '${entry.appointmentId}_$type${uniqueSuffix != null ? '_$uniqueSuffix' : ''}';
    try {
      final ref = _firestore.collection('notifications').doc(id);
      final existing = await ref.get();
      if (existing.exists) return; // don't reset isRead on repeat events
      await ref.set({
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        'status': 'unread',
        'isRead': false,
        'tokenNumber': entry.tokenCode,
        'hospitalName': session.hospitalName,
        'clinicName': session.departmentName,
        'dateTime': DateTime.now().toIso8601String(),
        'nowServing': session.currentTokenServing,
        'peopleAhead': '${entry.peopleAhead}',
        'estimatedWait': '~${entry.estimatedWaitMinutes} mins',
        'affectedOPD': session.departmentName,
        'delayTime': session.delayMinutes > 0 ? '${session.delayMinutes} mins' : null,
        'patientId': entry.patientId,
        'patientNic': currentPatientNic,
        'appointmentId': entry.appointmentId,
        'source': 'module3_live_queue',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('LiveQueueService notification write notice: $e');
    }
  }

  // ── Patient actions ───────────────────────────────────────────────────────

  /// Rejoin after a missed turn: placed behind the next 2 waiting patients.
  Future<bool> rejoinQueue(String reason) async {
    final apptId = _myApptId;
    if (apptId == null) return false;
    try {
      final waiting = _queue
          .where((e) =>
              e.appointmentId != apptId &&
              (e.status == PatientQueueStatus.waiting ||
                  e.status == PatientQueueStatus.approaching ||
                  e.status == PatientQueueStatus.delayed ||
                  e.status == PatientQueueStatus.called))
          .toList();

      double order;
      double orderOfEntry(QueueEntryModel e) {
        final d = _rawDoc(e.appointmentId);
        return d != null ? _orderOf(d) : e.queuePosition.toDouble();
      }

      if (waiting.length >= 3) {
        order = (orderOfEntry(waiting[1]) + orderOfEntry(waiting[2])) / 2;
      } else if (waiting.isNotEmpty) {
        order = orderOfEntry(waiting.last) + 0.5;
      } else {
        order = _myAppt != null ? _orderOf(_myAppt!) : 0;
      }

      await _firestore.collection('appointments').doc(apptId).update({
        'status': 'confirmed',
        'queueOrder': order,
        'rejoinRequested': true,
        'rejoinReason': reason,
        'rejoinedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Dual-sync: update queue_entries if document exists for this appointment
      try {
        final qEntrySnap = await _firestore
            .collection('queue_entries')
            .where('appointmentId', isEqualTo: apptId)
            .limit(1)
            .get();
        if (qEntrySnap.docs.isNotEmpty) {
          await qEntrySnap.docs.first.reference.update({
            'status': 'waiting',
            'rejoinRequested': true,
            'rejoinReason': reason,
            'rejoinedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('rejoin queue_entries sync notice: $e');
      }

      _pushNotification(
        type: 'rejoined',
        title: 'Rejoined the queue',
        message: 'Token ${myEntry.tokenCode} has been placed back in the queue. Reason: $reason',
        uniqueSuffix: '${DateTime.now().millisecondsSinceEpoch}',
      );
      return true;
    } catch (e) {
      debugPrint('Error rejoining queue: $e');
      return false;
    }
  }

  /// Spec method: Rejoin specific queue entry via atomic transaction
  Future<bool> rejoinQueueEntry(String queueEntryId, {String reason = 'Requested rejoin'}) async {
    try {
      final entryRef = _firestore.collection('queue_entries').doc(queueEntryId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(entryRef);
        if (snap.exists) {
          tx.update(entryRef, {
            'status': 'waiting',
            'rejoinRequested': true,
            'rejoinReason': reason,
            'rejoinedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      return await rejoinQueue(reason);
    } catch (e) {
      debugPrint('rejoinQueueEntry notice: $e');
      return await rejoinQueue(reason);
    }
  }

  // ── Clinic simulator (stand-in for Module 4 until it is merged) ───────────
  // These write to Firestore with exactly the same contract Module 4 uses,
  // so every device / module sees the change in real time.

  Future<void> simulateCallMe() => _updateMyStatus('called', {'calledAt': FieldValue.serverTimestamp()});
  Future<void> simulateMissed() => _updateMyStatus('missed', {'missedAt': FieldValue.serverTimestamp()});
  Future<void> simulateCompleted() => _updateMyStatus('completed', {'completedAt': FieldValue.serverTimestamp()});
  Future<void> simulateResetToWaiting() => _updateMyStatus('confirmed', {});

  /// Doctor finishes the current patient and calls the next one.
  Future<void> simulateAdvanceQueue() async {
    final batch = _firestore.batch();
    final called = _queue.where((e) => e.status == PatientQueueStatus.called).toList();
    final next = _queue.where((e) =>
        e.status == PatientQueueStatus.waiting ||
        e.status == PatientQueueStatus.approaching ||
        e.status == PatientQueueStatus.delayed);
    for (final c in called) {
      batch.update(_firestore.collection('appointments').doc(c.appointmentId), {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (next.isNotEmpty) {
      batch.update(_firestore.collection('appointments').doc(next.first.appointmentId), {
        'status': 'called',
        'calledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('simulateAdvanceQueue error: $e');
    }
  }

  /// Doctor / clinic announces (or clears) a delay.
  Future<void> simulateDelay(bool delayed, {int minutes = 25, String? reason}) async {
    final s = session;
    if (s.sessionId.isEmpty) return;
    try {
      await _firestore.collection('queue_sessions').doc(s.sessionId).set({
        'hospitalId': s.hospitalId,
        'departmentId': s.departmentId,
        'appointmentDate': appointmentDate,
        'status': delayed ? 'delayed' : 'active',
        'delayMinutes': delayed ? minutes : 0,
        'delayReason': delayed ? (reason ?? 'Emergency patient admitted to the consultation room') : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('simulateDelay error: $e');
    }
  }

  Future<void> _updateMyStatus(String status, Map<String, dynamic> extra) async {
    final apptId = _myApptId;
    if (apptId == null) return;
    try {
      await _firestore.collection('appointments').doc(apptId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        ...extra,
      });
    } catch (e) {
      debugPrint('Queue status update error: $e');
    }
  }

  /// Interactive state switcher for presentation and demoing
  void setQueueStatus(PatientQueueStatus newStatus) {
    if (_myApptId != null) {
      switch (newStatus) {
        case PatientQueueStatus.called:
          simulateCallMe();
          break;
        case PatientQueueStatus.missed:
          simulateMissed();
          break;
        case PatientQueueStatus.completed:
          simulateCompleted();
          break;
        case PatientQueueStatus.waiting:
        default:
          simulateResetToWaiting();
          break;
      }
    } else {
      if (_entry != null) {
        _entry = QueueEntryModel(
          queueEntryId: _entry!.queueEntryId,
          appointmentId: _entry!.appointmentId,
          patientId: _entry!.patientId,
          patientName: _entry!.patientName,
          tokenCode: _entry!.tokenCode,
          queuePosition: _entry!.queuePosition,
          peopleAhead: (newStatus == PatientQueueStatus.called) ? 0 : _entry!.peopleAhead,
          status: newStatus,
          estimatedWaitMinutes: (newStatus == PatientQueueStatus.called) ? 0 : _entry!.estimatedWaitMinutes,
          rejoinRequested: _entry!.rejoinRequested,
          rejoinReason: _entry!.rejoinReason,
          joinedAt: _entry!.joinedAt,
          calledAt: (newStatus == PatientQueueStatus.called) ? DateTime.now() : _entry!.calledAt,
        );
        notifyListeners();
      }
    }
  }

  /// Toggle clinic delay
  void toggleDelay(bool isDelayed, {int minutes = 25, String? reason}) {
    if (_myApptId != null) {
      simulateDelay(isDelayed, minutes: minutes, reason: reason);
    } else {
      if (_session != null) {
        _session = QueueSessionModel(
          sessionId: _session!.sessionId,
          hospitalId: _session!.hospitalId,
          hospitalName: _session!.hospitalName,
          departmentId: _session!.departmentId,
          departmentName: _session!.departmentName,
          roomNumber: _session!.roomNumber,
          doctorName: _session!.doctorName,
          currentTokenServing: _session!.currentTokenServing,
          totalTokens: _session!.totalTokens,
          estimatedMinutesPerPatient: _session!.estimatedMinutesPerPatient,
          status: isDelayed ? QueueSessionStatus.delayed : QueueSessionStatus.active,
          delayMinutes: isDelayed ? minutes : 0,
          delayReason: isDelayed ? (reason ?? 'Emergency trauma patient admitted') : null,
          lastUpdated: DateTime.now(),
        );
        if (_entry != null) {
          final baseWait = _entry!.peopleAhead * _session!.estimatedMinutesPerPatient;
          final totalWait = baseWait + _session!.delayMinutes;
          _entry = QueueEntryModel(
            queueEntryId: _entry!.queueEntryId,
            appointmentId: _entry!.appointmentId,
            patientId: _entry!.patientId,
            patientName: _entry!.patientName,
            tokenCode: _entry!.tokenCode,
            queuePosition: _entry!.queuePosition,
            peopleAhead: _entry!.peopleAhead,
            status: _session!.isDelayed ? PatientQueueStatus.delayed : _entry!.status,
            estimatedWaitMinutes: totalWait > 0 ? totalWait : 0,
            rejoinRequested: _entry!.rejoinRequested,
            rejoinReason: _entry!.rejoinReason,
            joinedAt: _entry!.joinedAt,
            calledAt: _entry!.calledAt,
          );
        }
        notifyListeners();
      }
    }
  }

  void _initFallbackState() {
    _session = QueueSessionModel(
      sessionId: 'session_demo_01',
      hospitalId: 'hosp_colombo_general',
      hospitalName: 'General Hospital Colombo',
      departmentId: 'dept_opd_general',
      departmentName: 'General Medicine OPD',
      roomNumber: 'Room 04',
      doctorName: 'Dr. H. M. Perera',
      currentTokenServing: 'A-008',
      totalTokens: 40,
      estimatedMinutesPerPatient: 4,
      status: QueueSessionStatus.active,
      delayMinutes: 0,
      lastUpdated: DateTime.now(),
    );

    _entry = QueueEntryModel(
      queueEntryId: 'entry_014',
      appointmentId: 'apt_demo_014',
      patientId: 'patient_001',
      patientName: 'Kamal Gunaratne',
      tokenCode: 'A-014',
      queuePosition: 14,
      peopleAhead: 6,
      status: PatientQueueStatus.waiting,
      estimatedWaitMinutes: 24,
      joinedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String sessionIdFor(String hospitalId, String departmentId, String date) =>
      '${hospitalId}_${departmentId}_$date';

  Map<String, dynamic>? _rawDoc(String id) {
    if (id == _myApptId) return _myAppt;
    for (final d in _deptDocs) {
      if (d.id == id) return d.data();
    }
    return null;
  }

  static String _statusOf(Map<String, dynamic> data) =>
      (data['status'] ?? 'confirmed').toString().toLowerCase();

  static bool _isFinished(String status) =>
      status == 'completed' || status == 'done' || status == 'cancelled';

  static PatientQueueStatus _mapStatus(String status) {
    switch (status) {
      case 'called':
      case 'serving':
      case 'in_consultation':
        return PatientQueueStatus.called;
      case 'completed':
      case 'done':
        return PatientQueueStatus.completed;
      case 'missed':
      case 'no_show':
        return PatientQueueStatus.missed;
      default: // confirmed, rescheduled, booked, waiting
        return PatientQueueStatus.waiting;
    }
  }

  /// Queue order: explicit `queueOrder` (set on rejoin) or the token number.
  static double _orderOf(Map<String, dynamic> data) {
    final explicit = data['queueOrder'];
    if (explicit is num) return explicit.toDouble();
    final digits = RegExp(r'\d+').firstMatch((data['tokenCode'] ?? '').toString());
    return digits != null ? double.parse(digits.group(0)!) : 9999;
  }

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static String _todayString() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  QueueSessionModel _emptySession() => QueueSessionModel(
        sessionId: '',
        hospitalId: '',
        hospitalName: 'No active clinic',
        departmentId: '',
        departmentName: '—',
        roomNumber: '—',
        doctorName: '—',
        currentTokenServing: '—',
        totalTokens: 0,
        lastUpdated: DateTime.now(),
      );

  QueueEntryModel _emptyEntry() => QueueEntryModel(
        queueEntryId: '',
        appointmentId: '',
        patientId: '',
        patientName: '',
        tokenCode: '—',
        queuePosition: 0,
        peopleAhead: 0,
        estimatedWaitMinutes: 0,
        joinedAt: DateTime.now(),
      );
}
