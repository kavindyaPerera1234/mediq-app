import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';
import '../models/notification_model.dart';
import 'notification_detail_screen.dart';
import 'notification_settings_screen.dart';

class NotificationCentreScreen extends StatelessWidget {
  const NotificationCentreScreen({
    super.key,
  });

  String get _currentUserId {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        if (user.userId.isNotEmpty) return user.userId;
        if (user.nic != null && user.nic!.isNotEmpty) return user.nic!;
        if (user.phoneNumber.isNotEmpty) return user.phoneNumber;
      }
    } catch (_) {}
    return '200164801234';
  }

  Set<String> get _validUserIds {
    final ids = <String>{_currentUserId, 'all', 'broadcast'};
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        if (user.userId.isNotEmpty) ids.add(user.userId);
        if (user.nic != null && user.nic!.isNotEmpty) ids.add(user.nic!);
        if (user.phoneNumber.isNotEmpty) ids.add(user.phoneNumber);
      }
    } catch (_) {}
    return ids;
  }

  List<NotificationModel> _fallbackNotifications() {
    return [
      NotificationModel(
        id: "1",
        type: "near_turn",
        title: "Your Turn is Approaching",
        message: "2 patients ahead — please be ready outside OPD Room 3.",
        status: "NEW",
        isRead: false,
        tokenNumber: "A-024",
      ),
      NotificationModel(
        id: "2",
        type: "delay",
        title: "OPD Queue Delayed",
        message: "General Medicine OPD delayed by ~30 mins.",
        status: "NEW",
        isRead: false,
        tokenNumber: "A-024",
      ),
      NotificationModel(
        id: "3",
        type: "missed_token",
        title: "Missed Token Alert",
        message: "Token A-024 was called but you were not present. Tap to rejoin queue.",
        status: "NEW",
        isRead: false,
        tokenNumber: "A-024",
      ),
      NotificationModel(
        id: "4",
        type: "appointment_confirmed",
        title: "Appointment Confirmed",
        message: "Token A-024 for General Medicine, National Hospital Sri Lanka.",
        status: "NEW",
        isRead: false,
        tokenNumber: "A-024",
      ),
      NotificationModel(
        id: "5",
        type: "reminder",
        title: "OPD Reminder",
        message: "Tomorrow at 8:30 AM — National Hospital of Sri Lanka.",
        status: "NEW",
        isRead: false,
        tokenNumber: "A-024",
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppAccessibility.isHighContrastMode,
      builder: (context, _) {
        final isDark = AppAccessibility.isHighContrastMode.value;

        return Scaffold(
          backgroundColor: isDark ? AppColors.seniorHighContrastBg : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.seniorHighContrastSurface : Colors.white,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Notifications",
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "Sri Lanka National Health Alerts",
                  style: TextStyle(
                    color: isDark ? AppColors.seniorHighContrastAccent : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .snapshots(),
        builder: (context, snapshot) {
          List<NotificationModel> displayList = [];
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final validIds = _validUserIds;
            final matchedDocs = snapshot.data!.docs.where((doc) {
              final data = doc.data();
              final uId = (data['userId'] ?? '').toString().trim();
              final pId = (data['patientId'] ?? '').toString().trim();
              final pNic = (data['patientNic'] ?? '').toString().trim();
              final pPhone = (data['phone'] ?? data['phoneNumber'] ?? '').toString().trim();
              final isBcast = data['isBroadcast'] == true ||
                  data['broadcast'] == true ||
                  uId == 'all' ||
                  uId == 'broadcast';

              return isBcast ||
                  validIds.contains(uId) ||
                  validIds.contains(pId) ||
                  validIds.contains(pNic) ||
                  validIds.contains(pPhone);
            }).toList();

            if (matchedDocs.isNotEmpty) {
              matchedDocs.sort((a, b) {
                final ta = a.data()['createdAt'];
                final tb = b.data()['createdAt'];
                if (ta is Timestamp && tb is Timestamp) {
                  return tb.compareTo(ta);
                }
                return 0;
              });

              displayList = matchedDocs.map((doc) {
                return NotificationModel.fromFirestore(doc.id, doc.data());
              }).toList();
            }
          }
          
          if (displayList.isEmpty) {
            displayList = _fallbackNotifications();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final notification = displayList[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationDetailScreen(
                        notification: notification,
                      ),
                    ),
                  );
                },
                child: notificationCard(notification, isDark: isDark),
              );
            },
          );
        },
      ),
    );
      },
    );
  }

  Widget notificationCard(NotificationModel notification, {bool isDark = false}) {
    Color color;
    IconData icon;
    switch (notification.type) {
      case "near_turn":
      case "queue_approaching":
      case "caregiver_queue_approaching":
        color = Colors.orange;
        icon = Icons.notifications_active_outlined;
        break;
      case "delay":
      case "delay_broadcast":
      case "queue_delayed":
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case "missed_token":
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case "your_turn":
      case "caregiver_your_turn":
        color = Colors.red;
        icon = Icons.priority_high_rounded;
        break;
      case "appointment_confirmed":
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      default:
        color = Colors.blue;
        icon = Icons.calendar_month_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.seniorHighContrastSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.seniorHighContrastBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (notification.status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: notification.status == "NEW"
                              ? (isDark ? Colors.red.withValues(alpha: 0.25) : Colors.red.shade50)
                              : (isDark ? Colors.grey.withValues(alpha: 0.25) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(4),
                          border: isDark ? Border.all(color: notification.status == "NEW" ? Colors.redAccent : Colors.grey) : null,
                        ),
                        child: Text(
                          notification.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: notification.status == "NEW"
                                ? (isDark ? Colors.redAccent : Colors.red)
                                : (isDark ? Colors.grey.shade300 : Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}