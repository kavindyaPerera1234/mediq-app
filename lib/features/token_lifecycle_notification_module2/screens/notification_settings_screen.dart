import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}


class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool appNotifications = true;
  bool smsNotifications = true;
  bool appointmentConfirmation = true;
  bool queueApproaching = true;
  bool opdDelay = true;
  bool appointmentReminder = false;

  @override
  Widget build(BuildContext context) {
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
              "Notification Settings",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize:18,
              ),
            ),
            Text(
              "Preferences",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize:12,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionCard(
              title: "NOTIFICATION DELIVERY",
              children: [
                _switchTile(
                  title: "App Notifications",
                  subtitle:
                  "Receive live updates directly in-app",
                  value: appNotifications,
                  onChanged: (value){
                    setState((){
                      appNotifications=value;
                    });
                  },
                ),
                _switchTile(
                  title: "SMS Notifications",
                  subtitle:
                  "Recommended for areas with weak internet",
                  value: smsNotifications,
                  onChanged: (value){
                    setState((){
                      smsNotifications=value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height:16),
            _sectionCard(
              title: "NOTIFY ME ABOUT:",
              children: [
                _switchTile(
                  title:"Appointment confirmations",
                  value: appointmentConfirmation,
                  onChanged:(value){
                    setState((){
                      appointmentConfirmation=value;
                    });
                  },
                ),
                _switchTile(
                  title:"Queue approaching turn",
                  value: queueApproaching,
                  onChanged:(value){
                    setState((){
                      queueApproaching=value;
                    });
                  },
                ),
                _switchTile(
                  title:"OPD delays",
                  value: opdDelay,
                  onChanged:(value){
                    setState((){
                      opdDelay=value;
                    });
                  },
                ),
                _switchTile(
                  title:"Appointment reminders",
                  value: appointmentReminder,
                  onChanged:(value){
                    setState((){
                      appointmentReminder=value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height:16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "SMS notifications work on all phone types, "
                "including basic/keypad phones. Safely integrated with MOH.",
                style: TextStyle(
                  fontSize:12,
                ),
              ),
            ),
            const SizedBox(height:20),
            SizedBox(
              width:double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                  const EdgeInsets.symmetric(vertical:15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (){
                  // saveNotificationPreferences()
                },
                child: const Text(
                  "Save Preferences",
                  style: TextStyle(
                    color:Colors.white,
                    fontWeight:FontWeight.bold,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }){
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize:12,
              fontWeight:FontWeight.bold,
            ),
          ),

          const SizedBox(height:8),
          ...children,
        ],
      ),
    );
  }
  Widget _switchTile({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
    }){
    return Material(
        color: Colors.transparent,
        child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
            title,
            style: const TextStyle(
                fontSize:14,
                fontWeight:FontWeight.w500,
            ),
        ),
        subtitle: subtitle == null? null: Text(
            subtitle,
            style: const TextStyle(
                fontSize:11,
                color:Colors.grey,
            ),
        ),

        value:value,

        onChanged:onChanged,

        activeColor: AppColors.primary,

        ),

    );
    }
}