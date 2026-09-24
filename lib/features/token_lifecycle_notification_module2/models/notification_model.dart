class NotificationModel {
  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String dateTime;
  final bool isRead;


  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.dateTime,
    required this.isRead,
  });


  // Firestore → Model
  factory NotificationModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return NotificationModel(
      notificationId: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      dateTime: data['dateTime'] ?? '',
      isRead: data['isRead'] ?? false,
    );
  }


  // Model → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'dateTime': dateTime,
      'isRead': isRead,
    };
  }
}