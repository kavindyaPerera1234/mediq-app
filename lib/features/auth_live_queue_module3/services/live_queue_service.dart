import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_session_model.dart';
import '../models/queue_entry_model.dart';

class LiveQueueService extends ChangeNotifier {
  static final LiveQueueService _instance = LiveQueueService._internal();
  factory LiveQueueService() => _instance;
  LiveQueueService._internal() {
    _initDefaultState();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  QueueSessionModel? _currentSession;
  QueueEntryModel? _myEntry;

  QueueSessionModel get session => _currentSession ?? _demoSession;
  QueueEntryModel get myEntry => _myEntry ?? _demoEntry;

  // Stream controllers for real-time reactivity
  final _sessionController = StreamController<QueueSessionModel>.broadcast();
  final _entryController = StreamController<QueueEntryModel>.broadcast();

  Stream<QueueSessionModel> get sessionStream => _sessionController.stream;
  Stream<QueueEntryModel> get entryStream => _entryController.stream;

  // Default demo state matching Milestone 2 prototype
  late QueueSessionModel _demoSession;
  late QueueEntryModel _demoEntry;

  void _initDefaultState() {
    _demoSession = QueueSessionModel(
      sessionId: 'session_gyn_01',
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

    _demoEntry = QueueEntryModel(
      queueEntryId: 'entry_014',
      appointmentId: 'apt_014',
      patientId: 'patient_001',
      patientName: 'Kamal Gunaratne',
      tokenCode: 'A-014',
      queuePosition: 14,
      peopleAhead: 6, // 14 - 8 = 6
      status: PatientQueueStatus.waiting,
      estimatedWaitMinutes: 24, // 6 * 4 = 24 mins
      joinedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    );

    _currentSession = _demoSession;
    _myEntry = _demoEntry;
  }

  /// Real-time listener for Queue Session from Firestore
  void listenToQueueSession(String sessionId) {
    _firestore
        .collection('queue_sessions')
        .doc(sessionId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _currentSession = QueueSessionModel.fromMap(snapshot.data()!, id: snapshot.id);
        _recalculateWaitTime();
        _sessionController.add(_currentSession!);
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint("Firestore session stream notice: $e (using local state)");
    });
  }

  /// Real-time listener for Patient's Queue Entry
  void listenToQueueEntry(String entryId) {
    _firestore
        .collection('queue_entries')
        .doc(entryId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _myEntry = QueueEntryModel.fromMap(snapshot.data()!, id: snapshot.id);
        _entryController.add(_myEntry!);
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint("Firestore entry stream notice: $e (using local state)");
    });
  }

  /// Rejoin Queue Action (Milestone 2 core feature)
  Future<bool> rejoinQueue(String reason) async {
    try {
      _myEntry = QueueEntryModel(
        queueEntryId: myEntry.queueEntryId,
        appointmentId: myEntry.appointmentId,
        patientId: myEntry.patientId,
        patientName: myEntry.patientName,
        tokenCode: myEntry.tokenCode,
        queuePosition: session.totalTokens + 1,
        peopleAhead: 2, // Rejoining places them with small buffer
        status: PatientQueueStatus.waiting,
        estimatedWaitMinutes: 10,
        rejoinRequested: true,
        rejoinReason: reason,
        joinedAt: DateTime.now(),
      );

      // Attempt Firestore update
      try {
        await _firestore
            .collection('queue_entries')
            .doc(myEntry.queueEntryId)
            .update({
          'status': PatientQueueStatus.waiting.name,
          'rejoinRequested': true,
          'rejoinReason': reason,
        });
      } catch (_) {}

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error rejoining queue: $e");
      return false;
    }
  }

  /// Interactive state switcher for presentation and demoing
  void setQueueStatus(PatientQueueStatus newStatus) {
    _myEntry = QueueEntryModel(
      queueEntryId: myEntry.queueEntryId,
      appointmentId: myEntry.appointmentId,
      patientId: myEntry.patientId,
      patientName: myEntry.patientName,
      tokenCode: myEntry.tokenCode,
      queuePosition: myEntry.queuePosition,
      peopleAhead: (newStatus == PatientQueueStatus.called) ? 0 : myEntry.peopleAhead,
      status: newStatus,
      estimatedWaitMinutes: (newStatus == PatientQueueStatus.called) ? 0 : myEntry.estimatedWaitMinutes,
      rejoinRequested: myEntry.rejoinRequested,
      rejoinReason: myEntry.rejoinReason,
      joinedAt: myEntry.joinedAt,
      calledAt: (newStatus == PatientQueueStatus.called) ? DateTime.now() : myEntry.calledAt,
    );
    notifyListeners();
  }

  /// Toggle clinic delay
  void toggleDelay(bool isDelayed, {int minutes = 25, String? reason}) {
    _demoSession = QueueSessionModel(
      sessionId: session.sessionId,
      hospitalId: session.hospitalId,
      hospitalName: session.hospitalName,
      departmentId: session.departmentId,
      departmentName: session.departmentName,
      roomNumber: session.roomNumber,
      doctorName: session.doctorName,
      currentTokenServing: session.currentTokenServing,
      totalTokens: session.totalTokens,
      estimatedMinutesPerPatient: session.estimatedMinutesPerPatient,
      status: isDelayed ? QueueSessionStatus.delayed : QueueSessionStatus.active,
      delayMinutes: isDelayed ? minutes : 0,
      delayReason: isDelayed ? (reason ?? 'Emergency trauma patient admitted') : null,
      lastUpdated: DateTime.now(),
    );
    _currentSession = _demoSession;
    _recalculateWaitTime();
    notifyListeners();
  }

  void _recalculateWaitTime() {
    if (_myEntry != null && _currentSession != null) {
      final baseWait = _myEntry!.peopleAhead * _currentSession!.estimatedMinutesPerPatient;
      final totalWait = baseWait + _currentSession!.delayMinutes;
      _myEntry = QueueEntryModel(
        queueEntryId: _myEntry!.queueEntryId,
        appointmentId: _myEntry!.appointmentId,
        patientId: _myEntry!.patientId,
        patientName: _myEntry!.patientName,
        tokenCode: _myEntry!.tokenCode,
        queuePosition: _myEntry!.queuePosition,
        peopleAhead: _myEntry!.peopleAhead,
        status: _currentSession!.isDelayed ? PatientQueueStatus.delayed : _myEntry!.status,
        estimatedWaitMinutes: totalWait > 0 ? totalWait : 0,
        rejoinRequested: _myEntry!.rejoinRequested,
        rejoinReason: _myEntry!.rejoinReason,
        joinedAt: _myEntry!.joinedAt,
        calledAt: _myEntry!.calledAt,
      );
    }
  }
}
