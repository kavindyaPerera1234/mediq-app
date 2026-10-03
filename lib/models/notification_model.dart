import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String userId;
  final String type; // queue_delayed, your_turn, missed_token, queue_completed
  final String title;
  final String message;
  final String appointmentId;
  final String queueEntryId;
  final String queueSessionId;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.appointmentId = '',
    this.queueEntryId = '',
    this.queueSessionId = '',
    this.isRead = false,
    this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      notificationId: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      queueEntryId: data['queueEntryId'] ?? '',
      queueSessionId: data['queueSessionId'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'appointmentId': appointmentId,
      'queueEntryId': queueEntryId,
      'queueSessionId': queueSessionId,
      'isRead': isRead,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }
}
