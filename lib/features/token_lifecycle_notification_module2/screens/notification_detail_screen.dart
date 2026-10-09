import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/notification_model.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  String _value(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not available';
    }
    return value.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          _appBarTitle(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildScreen(),
      ),
    );
  }

  String _appBarTitle() {
    if (notification.type == "missed_token") {
      return "Token Status";
    }

    return "Notification";
  }

  Widget _buildScreen() {
    switch (notification.type) {
      case "near_turn":
      case "queue_approaching":
      case "caregiver_queue_approaching":
        return nearTurn();

      case "delay":
      case "delay_broadcast":
      case "queue_delayed":
        return delay();

      case "missed_token":
        return missedToken();

      case "appointment_confirmed":
        return appointmentConfirmed();

      case "reminder":
        return opdReminder();

      default:
        return normal();
    }
  }

  Widget nearTurn() {
    return Column(
      children: [
        const SizedBox(height: 20),

        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.orange.shade100,
          child: const Icon(
            Icons.notifications_none,
            color: Colors.orange,
            size: 30,
          ),
        ),

        const SizedBox(height: 15),

        Text(
          notification.title.isNotEmpty
              ? notification.title
              : "Your Turn is Approaching",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          notification.message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 25),

        detailCard([
          infoRow(
            Icons.confirmation_number_outlined,
            "YOUR TOKEN",
            _value(notification.tokenNumber),
          ),

          const Divider(),

          infoRow(
            Icons.medical_services,
            "NOW SERVING",
            _value(notification.nowServing),
          ),

          const Divider(),

          infoRow(
            Icons.people,
            "PEOPLE AHEAD",
            _value(notification.peopleAhead),
          ),

          const Divider(),

          infoRow(
            Icons.timer,
            "ESTIMATED WAIT",
            _value(notification.estimatedWait),
          ),

          const Divider(),

          infoRow(
            Icons.local_hospital_outlined,
            "HOSPITAL",
            _value(notification.hospitalName),
          ),

          const Divider(),

          infoRow(
            Icons.medical_services_outlined,
            "CLINIC / OPD",
            _value(notification.clinicName),
          ),

          const Divider(),

          infoRow(
            Icons.meeting_room_outlined,
            "OPD ROOM",
            _value(notification.roomNumber),
          ),
        ]),

        const SizedBox(height: 20),

        if (notification.roomNumber != null &&
            notification.roomNumber!.trim().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Please proceed to ${notification.roomNumber}.",
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget delay() {
    return Column(
      children: [
        detailCard([
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              notification.title.isNotEmpty
                  ? notification.title
                  : "OPD Queue Delayed",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 15),

          Text(
            notification.message,
            textAlign: TextAlign.center,
          ),

          const Divider(),

          infoRow(
            Icons.local_hospital,
            "AFFECTED OPD",
            _value(
              notification.affectedOPD ??
                  notification.clinicName,
            ),
          ),

          const Divider(),

          infoRow(
            Icons.timer_outlined,
            "ESTIMATED DELAY",
            _value(notification.delayTime),
          ),

          const Divider(),

          infoRow(
            Icons.confirmation_number,
            "YOUR TOKEN",
            _value(notification.tokenNumber),
          ),

          const Divider(),

          infoRow(
            Icons.meeting_room_outlined,
            "OPD ROOM",
            _value(notification.roomNumber),
          ),
        ]),
      ],
    );
  }

  Widget missedToken() {
    return Column(
      children: [
        const SizedBox(height: 20),

        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.red.shade50,
          child: const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 35,
          ),
        ),

        const SizedBox(height: 15),

        Text(
          notification.title.isNotEmpty
              ? notification.title
              : "You Missed Your Turn",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          notification.message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 20),

        detailCard([
          infoRow(
            Icons.confirmation_number,
            "YOUR TOKEN",
            _value(notification.tokenNumber),
          ),

          const Divider(),

          infoRow(
            Icons.local_hospital_outlined,
            "HOSPITAL",
            _value(notification.hospitalName),
          ),

          const Divider(),

          infoRow(
            Icons.medical_services_outlined,
            "CLINIC / OPD",
            _value(notification.clinicName),
          ),

          const Divider(),

          infoRow(
            Icons.meeting_room_outlined,
            "OPD ROOM",
            _value(notification.roomNumber),
          ),
        ]),
      ],
    );
  }

  Widget appointmentConfirmed() {
    return Column(
      children: [
        const SizedBox(height: 20),

        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.green.shade50,
          child: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 40,
          ),
        ),

        const SizedBox(height: 15),

        Text(
          notification.title.isNotEmpty
              ? notification.title
              : "Appointment Confirmed",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          notification.message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 20),

        detailCard([
          infoRow(
            Icons.confirmation_number_outlined,
            "YOUR TOKEN",
            _value(notification.tokenNumber),
          ),

          const Divider(),

          infoRow(
            Icons.person_outline,
            "PATIENT",
            _value(notification.patientName),
          ),

          const Divider(),

          infoRow(
            Icons.local_hospital_outlined,
            "HOSPITAL",
            _value(notification.hospitalName),
          ),

          const Divider(),

          infoRow(
            Icons.medical_services_outlined,
            "CLINIC / OPD",
            _value(notification.clinicName),
          ),

          const Divider(),

          infoRow(
            Icons.meeting_room_outlined,
            "OPD ROOM",
            _value(notification.roomNumber),
          ),

          const Divider(),

          infoRow(
            Icons.calendar_month_outlined,
            "DATE",
            _value(notification.appointmentDate),
          ),

          const Divider(),

          infoRow(
            Icons.access_time,
            "TIME SLOT",
            _value(notification.timeSlot),
          ),
        ]),
      ],
    );
  }

  Widget opdReminder() {
    return Column(
      children: [
        const SizedBox(height: 20),

        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade50,
          child: const Icon(
            Icons.calendar_month_outlined,
            color: Colors.blue,
            size: 40,
          ),
        ),

        const SizedBox(height: 15),

        Text(
          notification.title.isNotEmpty
              ? notification.title
              : "OPD Reminder",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          notification.message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 25),

        detailCard([
          infoRow(
            Icons.person_outline,
            "PATIENT",
            _value(notification.patientName),
          ),

          const Divider(),

          infoRow(
            Icons.local_hospital_outlined,
            "HOSPITAL",
            _value(notification.hospitalName),
          ),

          const Divider(),

          infoRow(
            Icons.medical_services_outlined,
            "CLINIC / OPD",
            _value(notification.clinicName),
          ),

          const Divider(),

          infoRow(
            Icons.meeting_room_outlined,
            "OPD ROOM",
            _value(notification.roomNumber),
          ),

          const Divider(),

          infoRow(
            Icons.calendar_today,
            "DATE",
            _value(notification.appointmentDate),
          ),

          const Divider(),

          infoRow(
            Icons.access_time,
            "TIME",
            _value(notification.timeSlot),
          ),

          const Divider(),

          infoRow(
            Icons.confirmation_number,
            "YOUR TOKEN",
            _value(notification.tokenNumber),
          ),
        ]),

        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "Please arrive 15 minutes before your appointment time.",
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget detailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget normal() {
    return detailCard([
      if (notification.title.isNotEmpty)
        Text(
          notification.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

      if (notification.title.isNotEmpty)
        const SizedBox(height: 12),

      Text(
        notification.message.isEmpty
            ? 'No notification details available.'
            : notification.message,
      ),
    ]);
  }
}