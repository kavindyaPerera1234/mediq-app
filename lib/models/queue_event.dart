import 'package:cloud_firestore/cloud_firestore.dart';

class QueueEvent {
  final String eventId;
  final String queueSessionId;
  final String queueEntryId;
  final String appointmentId;
  final String performedBy; // userId of doctor/nurse/staff
  final String eventType;
  final String previousStatus;
  final String newStatus;
  final DateTime? createdAt;

  QueueEvent({
    required this.eventId,
    required this.queueSessionId,
    this.queueEntryId = '',
    this.appointmentId = '',
    required this.performedBy,
    required this.eventType,
    this.previousStatus = '',
    this.newStatus = '',
    this.createdAt,
  });

  factory QueueEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return QueueEvent(
      eventId: doc.id,
      queueSessionId: data['queueSessionId'] ?? '',
      queueEntryId: data['queueEntryId'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      performedBy: data['performedBy'] ?? '',
      eventType: data['eventType'] ?? '',
      previousStatus: data['previousStatus'] ?? '',
      newStatus: data['newStatus'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'queueSessionId': queueSessionId,
      'queueEntryId': queueEntryId,
      'appointmentId': appointmentId,
      'performedBy': performedBy,
      'eventType': eventType,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
