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
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String tokenCode;
  final int queuePosition;
  final int peopleAhead;
  final PatientQueueStatus status;
  final int estimatedWaitMinutes;
  final bool rejoinRequested;
  final String? rejoinReason;
  final DateTime joinedAt;
  final DateTime? calledAt;

  QueueEntryModel({
    required this.queueEntryId,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.tokenCode,
    required this.queuePosition,
    required this.peopleAhead,
    this.status = PatientQueueStatus.waiting,
    this.estimatedWaitMinutes = 20,
    this.rejoinRequested = false,
    this.rejoinReason,
    required this.joinedAt,
    this.calledAt,
  });

  bool get isCalled => status == PatientQueueStatus.called;
  bool get isApproaching => status == PatientQueueStatus.approaching;
  bool get isMissed => status == PatientQueueStatus.missed;
  bool get isCompleted => status == PatientQueueStatus.completed;
  bool get isDelayed => status == PatientQueueStatus.delayed;

  Map<String, dynamic> toMap() {
    return {
      'queueEntryId': queueEntryId,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'tokenCode': tokenCode,
      'queuePosition': queuePosition,
      'peopleAhead': peopleAhead,
      'status': status.name,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'rejoinRequested': rejoinRequested,
      'rejoinReason': rejoinReason,
      'joinedAt': joinedAt.toIso8601String(),
      'calledAt': calledAt?.toIso8601String(),
    };
  }

  factory QueueEntryModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return QueueEntryModel(
      queueEntryId: id ?? map['queueEntryId'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? 'Kamal Gunaratne',
      tokenCode: map['tokenCode'] ?? 'A-014',
      queuePosition: (map['queuePosition'] as num?)?.toInt() ?? 14,
      peopleAhead: (map['peopleAhead'] as num?)?.toInt() ?? 5,
      status: PatientQueueStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == (map['status'] ?? 'waiting').toString().toLowerCase(),
        orElse: () => PatientQueueStatus.waiting,
      ),
      estimatedWaitMinutes: (map['estimatedWaitMinutes'] as num?)?.toInt() ?? 20,
      rejoinRequested: map['rejoinRequested'] ?? false,
      rejoinReason: map['rejoinReason'],
      joinedAt: map['joinedAt'] != null
          ? DateTime.tryParse(map['joinedAt']) ?? DateTime.now()
          : DateTime.now(),
      calledAt: map['calledAt'] != null ? DateTime.tryParse(map['calledAt']) : null,
    );
  }
}
