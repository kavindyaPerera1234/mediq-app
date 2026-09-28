import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/notification_model.dart';
import 'notification_detail_screen.dart';
import 'notification_settings_screen.dart';

class NotificationCentreScreen extends StatelessWidget {
  const NotificationCentreScreen({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final notifications = [
      NotificationModel(
        id: "1",
        type: "near_turn",
        title: "Your Turn is Approaching",
        message:
        "2 patients ahead — please be ready outside OPD Room 3.",
        status: "NEW",
        isRead: false,
        tokenNumber: "A-024",
      ),

      NotificationModel(
        id: "2",
        type: "delay",
        title: "OPD Queue Delayed",
        message:
        "General Medicine OPD delayed by ~30 mins.",
        status: "NEW",
        isRead: false,
        tokenNumber: "A-024",
      ),

      NotificationModel(
        id: "3",
        type: "missed_token",
        title: "Missed Token Alert",
        message:
        "Token A-024 was called but you were not present. Tap to rejoin queue.",
        status: "NEW",
        isRead: false,
        tokenNumber: "A-024",
      ),

      NotificationModel(
        id: "4",
        type: "appointment_confirmed",
        title: "Appointment Confirmed",
        message:
        "Token A-024 for General Medicine, National Hospital Sri Lanka.",
        status: "NEW",
        isRead: false,
        tokenNumber: "A-024",
      ),

      NotificationModel(
        id: "5",
        type: "reminder",
        title: "OPD Reminder",
        message:
        "Tomorrow at 8:30 AM — National Hospital of Sri Lanka.",
        status: "NEW",
        isRead: false,
        tokenNumber: "A-024",
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: (){
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Notifications",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Sri Lanka National Health Alerts",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
            Icons.settings_outlined,
            color: Colors.black87,
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
        ]
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context,index){
          final notification = notifications[index];
          return GestureDetector(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context)=>
                  NotificationDetailScreen(
                    notification: notification,
                  ),
                ),
              );
            },
            child: notificationCard(notification),
          );
        },
      ),
    );
  }
  Widget notificationCard(NotificationModel notification){
    Color color;
    IconData icon;
    switch(notification.type){
      case "near_turn":
        color = Colors.orange;
        icon = Icons.notifications_active_outlined;
        break;
      case "delay":
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case "missed_token":
        color = Colors.red;
        icon = Icons.error_outline;
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
      margin: const EdgeInsets.only(bottom:12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width:12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height:5),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize:12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}