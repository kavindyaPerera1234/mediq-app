import 'package:cloud_firestore/cloud_firestore.dart';

class QueueEntry {
  final String queueEntryId;
  final String queueSessionId;
  final String appointmentId;
  final String patientId;
  final String tokenNumber;
  final String tokenCode;
  final String status; // waiting, approaching, called, in_consultation, on_hold, missed, rejoined, completed, cancelled
  final int queuePosition;
  final int estimatedWaitMinutes;
  final String priority; // normal, elderly, pregnant, disabled, emergency
  final DateTime? calledAt;
  final DateTime? consultationStartedAt;
  final DateTime? completedAt;
  final DateTime? missedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined/Cached helper field for UI convenience
  final String? patientName;

  QueueEntry({
    required this.queueEntryId,
    required this.queueSessionId,
    required this.appointmentId,
    required this.patientId,
    required this.tokenNumber,
    required this.tokenCode,
    this.status = 'waiting',
    this.queuePosition = 0,
    this.estimatedWaitMinutes = 0,
    this.priority = 'normal',
    this.calledAt,
    this.consultationStartedAt,
    this.completedAt,
    this.missedAt,
    this.createdAt,
    this.updatedAt,
    this.patientName,
  });

  factory QueueEntry.fromFirestore(DocumentSnapshot doc, {String? patientName}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return QueueEntry(
      queueEntryId: doc.id,
      queueSessionId: data['queueSessionId'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      patientId: data['patientId'] ?? '',
      tokenNumber: data['tokenNumber'] ?? data['tokenCode'] ?? '',
      tokenCode: data['tokenCode'] ?? data['tokenNumber'] ?? '',
      status: (data['status'] == 'confirmed' || data['status'] == 'booked')
          ? 'waiting'
          : (data['status'] ?? 'waiting'),
      queuePosition: data['queuePosition'] ?? 0,
      estimatedWaitMinutes: data['estimatedWaitMinutes'] ?? 0,
      priority: data['priority'] ?? 'normal',
      calledAt: (data['calledAt'] as Timestamp?)?.toDate(),
      consultationStartedAt: (data['consultationStartedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      missedAt: (data['missedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      patientName: (patientName != null && patientName.isNotEmpty && patientName != 'Unknown Patient')
          ? patientName
          : (data['patientName'] ?? data['name'] ?? 'Patient'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'queueSessionId': queueSessionId,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'tokenNumber': tokenNumber,
      'tokenCode': tokenCode,
      'status': status,
      'queuePosition': queuePosition,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'priority': priority,
      'calledAt': calledAt != null ? Timestamp.fromDate(calledAt!) : null,
      'consultationStartedAt': consultationStartedAt != null ? Timestamp.fromDate(consultationStartedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'missedAt': missedAt != null ? Timestamp.fromDate(missedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  QueueEntry copyWith({
    String? status,
    String? priority,
    int? queuePosition,
    int? estimatedWaitMinutes,
    DateTime? calledAt,
    DateTime? consultationStartedAt,
    DateTime? completedAt,
    DateTime? missedAt,
    String? patientName,
  }) {
    return QueueEntry(
      queueEntryId: queueEntryId,
      queueSessionId: queueSessionId,
      appointmentId: appointmentId,
      patientId: patientId,
      tokenNumber: tokenNumber,
      tokenCode: tokenCode,
      status: status ?? this.status,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      priority: priority ?? this.priority,
      calledAt: calledAt ?? this.calledAt,
      consultationStartedAt: consultationStartedAt ?? this.consultationStartedAt,
      completedAt: completedAt ?? this.completedAt,
      missedAt: missedAt ?? this.missedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      patientName: patientName ?? this.patientName,
    );
  }
}
