import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/notification_model.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;
  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

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
          onPressed: (){
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildScreen(),
      ),
    );
  }

  String _appBarTitle(){

    if(notification.type=="missed_token"){
      return "Token Status";
    }
    return "Notification";
  }

  Widget _buildScreen(){
    switch(notification.type){
        case "near_turn":
            return nearTurn();
        case "delay":
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

  Widget nearTurn(){
    return Column(
      children: [
        const SizedBox(height:20),
        CircleAvatar(
          radius:28,
          backgroundColor: Colors.orange.shade100,
          child: const Icon(
            Icons.notifications_none,
            color: Colors.orange,
            size:30,
          ),
        ),
        const SizedBox(height:15),
        const Text(
          "Your Turn is Approaching!",
          style: TextStyle(
            fontSize:20,
            fontWeight:FontWeight.bold,
            color:Colors.orange,
          ),
        ),

        const Text(
          "Please make your way near OPD Counter",
          style:TextStyle(
            color:Colors.grey,
          ),
        ),

        const SizedBox(height:25),

        detailCard([
          infoRow(
              Icons.person,
              "YOUR TOKEN",
              "A-024"
          ),

          infoRow(
              Icons.medical_services,
              "NOW SERVING",
              "A-022"
          ),

          infoRow(
              Icons.people,
              "PEOPLE AHEAD",
              "2 Patients"
          ),

          infoRow(
              Icons.timer,
              "ESTIMATED WAIT",
              "~10 minutes"
          ),
       ]),

        const SizedBox(height:20),
        Container(
          padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(
            color:Colors.yellow.shade50,
            borderRadius:BorderRadius.circular(12),
          ),
          child:const Text(
            "Please proceed immediately to the General Medicine OPD waiting area outside Counter Room 3.",
          ),
        )
      ],
    );
  }

  Widget delay(){
    return Column(
      children:[
        detailCard([
          Container(
            padding:const EdgeInsets.all(10),
            decoration:BoxDecoration(
              color:Colors.orange.shade50,
              borderRadius:BorderRadius.circular(10),
            ),
            child:const Text(
              "⚠ OPD Delayed - General Medicine",
              style:TextStyle(
                fontWeight:FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height:15),
          Text(notification.message),
          const Divider(),
          infoRow(
              Icons.local_hospital,
              "Affected OPD",
              "General Medicine (Room 3)"
          ),
          infoRow(
              Icons.calendar_month,
              "Date & Time",
              "Sep 15, 2026 - 9:41 AM"
          ),
          infoRow(
              Icons.confirmation_number,
              "Your Token",
              "A-024"
          ),
        ]),

        const SizedBox(height:20),
        button("View Queue")
      ],
    );
  }

  Widget missedToken(){
    return Column(
      children:[
        const SizedBox(height:20),
        CircleAvatar(
          radius:30,
          backgroundColor:Colors.red.shade50,
          child:const Icon(
            Icons.error_outline,
            color:Colors.red,
            size:35,
          ),
        ),
        const SizedBox(height:15),
        const Text(
          "You Missed Your Turn",
          style:TextStyle(
            fontSize:20,
            fontWeight:FontWeight.bold,
            color:Colors.red,
          ),
        ),
        const SizedBox(height:20),
        detailCard([
          infoRow(
              Icons.confirmation_number,
              "YOUR TOKEN",
              "A-024"
          ),
          const Divider(),
          const Text(
            "Please contact the General Medicine OPD counter staff immediately or rejoin the queue below.",
            textAlign:TextAlign.center,
          )
        ]),
        const SizedBox(height:15),
        button("Rejoin Queue"),
        const SizedBox(height:10),
        outlinedButton("Contact OPD")
      ],
    );
  }

  Widget appointmentConfirmed(){
    return Column(
      children: [
        const SizedBox(height:20),
        CircleAvatar(
          radius:30,
          backgroundColor:Colors.green.shade50,
          child:const Icon(
            Icons.check_circle_outline,
            color:Colors.green,
            size:40,
          ),
        ),
        const SizedBox(height:15),
        const Text(
          "Appointment Confirmed",
          style:TextStyle(
            fontSize:22,
            fontWeight:FontWeight.bold,
            color:Colors.green,
          ),
        ),
        const SizedBox(height:8),
        const Text(
          "Your OPD appointment has been successfully confirmed.",
          textAlign:TextAlign.center,
          style:TextStyle(
          color:Colors.grey,
          ),
        ),
        detailCard([
          infoRow(
            Icons.confirmation_number_outlined,
            "YOUR TOKEN",
            notification.tokenNumber ?? "A-024",
          ),
          const Divider(),
          infoRow(
            Icons.person_outline,
            "PATIENT",
            "Kumara Perera",
          ),
          const Divider(),
          infoRow(
            Icons.local_hospital_outlined,
            "HOSPITAL",
            notification.hospitalName ??
            "National Hospital Sri Lanka",
          ),
          const Divider(),
          infoRow(
            Icons.medical_services_outlined,
            "CLINIC / OPD",
            notification.clinicName ??
            "General Medicine OPD",
          ),
          const Divider(),
          infoRow(
            Icons.calendar_month_outlined,
            "DATE",
            notification.dateTime ??
            "Monday, 15 September 2026",
          ),
          const Divider(),
          infoRow(
            Icons.access_time,
            "TIME SLOT",
            "8:30 AM - 9:00 AM",
          ),
        ]),
        const SizedBox(height:20),
        button("View Appointment Details"),
      ],
    );
  }

  Widget opdReminder(){
    return Column(
      children: [
        const SizedBox(height:20),
        CircleAvatar(
          radius:30,
          backgroundColor:Colors.blue.shade50,
          child:const Icon(
            Icons.calendar_month_outlined,
            color:Colors.blue,
            size:40,
          ),
        ),
        const SizedBox(height:15),
        const Text(
          "OPD Reminder",
            style:TextStyle(
            fontSize:22,
            fontWeight:FontWeight.bold,
            color:Colors.blue,
          ),
        ),

        const SizedBox(height:8),
        const Text(
          "Your appointment is scheduled for tomorrow.",
          textAlign:TextAlign.center,
          style:TextStyle(
          color:Colors.grey,
          ),
        ),

        const SizedBox(height:25),
        detailCard([
          infoRow(
            Icons.local_hospital_outlined,
            "HOSPITAL",
            notification.hospitalName ??
            "National Hospital Sri Lanka",
          ),
          const Divider(),
          infoRow(
            Icons.medical_services_outlined,
            "CLINIC",
            notification.clinicName ??
            "General Medicine OPD",
          ),
          const Divider(),
          infoRow(
            Icons.calendar_today,
            "DATE",
            "Tomorrow",
          ),
          const Divider(),
          infoRow(
            Icons.access_time,
            "TIME",
            "8:30 AM",
          ),
          const Divider(),
          infoRow(
            Icons.confirmation_number,
            "YOUR TOKEN",
            notification.tokenNumber ??
            "A-024",
          ),
        ]),
        const SizedBox(height:20),
        Container(
          width:double.infinity,
          padding:const EdgeInsets.all(15),
          decoration:BoxDecoration(
            color:Colors.blue.shade50,
            borderRadius:BorderRadius.circular(12)
          ),
          child:const Text(
            "Please arrive 15 minutes before your appointment time.",
            textAlign:TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget detailCard(List<Widget> children){
    return Container(
      width:double.infinity,
      padding:const EdgeInsets.all(18),
      decoration:BoxDecoration(
        color:Colors.white,
        borderRadius:BorderRadius.circular(16),
      ),
      child:Column(
        children:children,
      ),
    );
  }

  Widget infoRow(
      IconData icon,
      String title,
      String value
  ){
    return Padding(
      padding:const EdgeInsets.symmetric(vertical:10),
      child:Row(
        children:[
          Icon(
            icon,
            color:Colors.blue,
          ),
          const SizedBox(width:12),
          Expanded(
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text(
                  title,
                  style:const TextStyle(
                    fontSize:11,
                    color:Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style:const TextStyle(
                    fontWeight:FontWeight.bold,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget button(String text){
    return SizedBox(
      width:double.infinity,
      child:ElevatedButton(
        style:ElevatedButton.styleFrom(
          backgroundColor:AppColors.primary,
          padding:const EdgeInsets.all(14),
        ),
        onPressed:(){},
        child:Text(
          text,
          style:const TextStyle(
            color:Colors.white,
          ),
        ),
      ),
    );
  }

  Widget outlinedButton(String text){

    return SizedBox(
      width:double.infinity,
      child:OutlinedButton(
        onPressed:(){},
        child:Text(text),
      ),
    );

  }
  Widget normal(){
    return detailCard([
      Text(notification.message)
    ]);
  }
}