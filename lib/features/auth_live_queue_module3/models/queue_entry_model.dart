import 'package:cloud_firestore/cloud_firestore.dart';

enum PatientQueueStatus {
  waiting,
  approaching,
  called,
  delayed,
  missed,
  completed,
}

class QueueEntryModel {
  final String queueEntryId;
  final String queueSessionId;
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String tokenCode;
  final int tokenNumber;
  final int queuePosition;
  final int peopleAhead;
  final PatientQueueStatus status;
  final int estimatedWaitMinutes;
  final String priority; // 'normal', 'senior', 'emergency'
  final bool rejoinRequested;
  final String? rejoinReason;
  final DateTime joinedAt;
  final DateTime? calledAt;
  final DateTime? missedAt;
  final DateTime? rejoinedAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  QueueEntryModel({
    required this.queueEntryId,
    this.queueSessionId = '',
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.tokenCode,
    int? tokenNumber,
    required this.queuePosition,
    required this.peopleAhead,
    this.status = PatientQueueStatus.waiting,
    this.estimatedWaitMinutes = 20,
    this.priority = 'normal',
    this.rejoinRequested = false,
    this.rejoinReason,
    required this.joinedAt,
    this.calledAt,
    this.missedAt,
    this.rejoinedAt,
    this.completedAt,
    this.updatedAt,
  }) : tokenNumber = tokenNumber ?? _parseTokenNumber(tokenCode);

  QueueEntryModel copyWith({
    String? queueEntryId,
    String? queueSessionId,
    String? appointmentId,
    String? patientId,
    String? patientName,
    String? tokenCode,
    int? tokenNumber,
    int? queuePosition,
    int? peopleAhead,
    PatientQueueStatus? status,
    int? estimatedWaitMinutes,
    String? priority,
    bool? rejoinRequested,
    String? rejoinReason,
    DateTime? joinedAt,
    DateTime? calledAt,
    DateTime? missedAt,
    DateTime? rejoinedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return QueueEntryModel(
      queueEntryId: queueEntryId ?? this.queueEntryId,
      queueSessionId: queueSessionId ?? this.queueSessionId,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      tokenCode: tokenCode ?? this.tokenCode,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      queuePosition: queuePosition ?? this.queuePosition,
      peopleAhead: peopleAhead ?? this.peopleAhead,
      status: status ?? this.status,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      priority: priority ?? this.priority,
      rejoinRequested: rejoinRequested ?? this.rejoinRequested,
      rejoinReason: rejoinReason ?? this.rejoinReason,
      joinedAt: joinedAt ?? this.joinedAt,
      calledAt: calledAt ?? this.calledAt,
      missedAt: missedAt ?? this.missedAt,
      rejoinedAt: rejoinedAt ?? this.rejoinedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _parseTokenNumber(String code) {
    final digits = RegExp(r'\d+').firstMatch(code);
    return digits != null ? (int.tryParse(digits.group(0)!) ?? 1) : 1;
  }

  DateTime get createdAt => joinedAt;

  bool get isCalled => status == PatientQueueStatus.called;
  bool get isApproaching => status == PatientQueueStatus.approaching;
  bool get isMissed => status == PatientQueueStatus.missed;
  bool get isCompleted => status == PatientQueueStatus.completed;
  bool get isDelayed => status == PatientQueueStatus.delayed;

  Map<String, dynamic> toMap() {
    return {
      'queueEntryId': queueEntryId,
      'queueSessionId': queueSessionId,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'tokenCode': tokenCode,
      'tokenNumber': tokenNumber,
      'queuePosition': queuePosition,
      'peopleAhead': peopleAhead,
      'status': status.name,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'priority': priority,
      'rejoinRequested': rejoinRequested,
      'rejoinReason': rejoinReason,
      'joinedAt': joinedAt.toIso8601String(),
      'createdAt': joinedAt.toIso8601String(),
      'calledAt': calledAt?.toIso8601String(),
      'missedAt': missedAt?.toIso8601String(),
      'rejoinedAt': rejoinedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory QueueEntryModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final code = map['tokenCode'] ?? 'A-014';

    return QueueEntryModel(
      queueEntryId: id ?? map['queueEntryId'] ?? '',
      queueSessionId: map['queueSessionId'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? 'Kamal Gunaratne',
      tokenCode: code,
      tokenNumber: (map['tokenNumber'] as num?)?.toInt() ?? _parseTokenNumber(code),
      queuePosition: (map['queuePosition'] as num?)?.toInt() ?? 14,
      peopleAhead: (map['peopleAhead'] as num?)?.toInt() ?? 5,
      status: PatientQueueStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == (map['status'] ?? 'waiting').toString().toLowerCase(),
        orElse: () => PatientQueueStatus.waiting,
      ),
      estimatedWaitMinutes: (map['estimatedWaitMinutes'] as num?)?.toInt() ?? 20,
      priority: map['priority'] ?? 'normal',
      rejoinRequested: map['rejoinRequested'] ?? false,
      rejoinReason: map['rejoinReason'],
      joinedAt: parseDate(map['createdAt']) ?? parseDate(map['joinedAt']) ?? DateTime.now(),
      calledAt: parseDate(map['calledAt']),
      missedAt: parseDate(map['missedAt']),
      rejoinedAt: parseDate(map['rejoinedAt']),
      completedAt: parseDate(map['completedAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
