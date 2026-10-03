import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/constants/app_constants.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initializeNotificationFCM(String userId) async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _fcm.getToken();
        if (token != null && token.isNotEmpty) {
          await registerDeviceToken(userId, token);
        }
      }
    } catch (e) {
      print('FCM initialization warning (Web/Emulator/Platform): $e');
    }
  }

  Future<void> registerDeviceToken(String userId, String token) async {
    try {
      final docRef = _db.collection(AppConstants.deviceTokensCollection).doc('${userId}_$token');
      await docRef.set({
        'userId': userId,
        'token': token,
        'platform': 'mobile',
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving device token: $e');
    }
  }

  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String appointmentId = '',
    String queueEntryId = '',
    String queueSessionId = '',
  }) async {
    try {
      await _db.collection(AppConstants.notificationsCollection).add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'appointmentId': appointmentId,
        'queueEntryId': queueEntryId,
        'queueSessionId': queueSessionId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error writing notification: $e');
    }
  }
}
