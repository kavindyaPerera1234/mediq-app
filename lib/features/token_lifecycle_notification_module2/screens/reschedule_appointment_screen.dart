import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../token_lifecycle_notification_module2/screens/digital_token_details_screen.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
    final String hospital;
    final String clinic;
    final String doctor;
    final String date;
    final String time;
  const RescheduleAppointmentScreen({
    super.key,
    required this.hospital,
    required this.clinic,
    required this.doctor,
    required this.date,
    required this.time,
  });
  @override
  State<RescheduleAppointmentScreen> createState() =>
      _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState
    extends State<RescheduleAppointmentScreen> {
    late String selectedDate;
    late String selectedTime;
    final List<String> timeSlots = [
        "09:00 AM",
        "10:30 AM",
        "11:30 AM",
        "02:00 PM",
        "03:30 PM",
    ];

    @override
    void initState() {
        super.initState();

        selectedDate = widget.date;
        selectedTime = widget.time;
    }

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
        title: Text(
          "Reschedule Appointment",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                _appointmentCard(),
                const SizedBox(height:20),
                Text(
                    "Choose New Date",
                    style: TextStyle(
                        fontSize:16,
                        fontWeight:FontWeight.bold,
                        color:AppColors.textPrimary,
                    ),
                ),
                const SizedBox(height:10),
                GestureDetector(
                    onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2027),
                        );
                        if(pickedDate != null){
                            setState((){
                                selectedDate = "${pickedDate.day} ${pickedDate.month} ${pickedDate.year}";
                            });

                        }
                    },
                    child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),

                        ),
                        child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                                Text(
                                    selectedDate,
                                    style: const TextStyle(
                                        fontSize:15,
                                        fontWeight:FontWeight.w500,
                                    ),

                                ),
                                Icon(
                                    Icons.calendar_month,
                                    color:AppColors.primary,
                                ),

                            ],

                        ),

                    ),

                ),
                        
                const SizedBox(height:20),
                Text(
                    "Available Time Slots",
                    style: TextStyle(
                        fontSize:16,
                        fontWeight:FontWeight.bold,
                        color:AppColors.textPrimary,
                    ),
                ),
                const SizedBox(height:10),
                    Wrap(
                    spacing:10,
                    runSpacing:10,
                    children: timeSlots.map((time){
                        bool selected = time == selectedTime;
                        return GestureDetector(
                            onTap: (){
                                setState((){
                                selectedTime = time;
                            });
                        },
                        child: Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal:18,
                                vertical:12,
                            ),
                            decoration: BoxDecoration(
                                color:selected ? AppColors.primary: Colors.white,
                                borderRadius:
                                BorderRadius.circular(12),
                                border:Border.all(
                                    color:AppColors.primary,
                                ),
                            ),
                            child: Text(
                                time,
                                style: TextStyle(
                                    color:selected ? Colors.white: AppColors.primary,
                                    fontWeight:FontWeight.w600,
                                ),
                            ),
                        ),
                    );
                }).toList(),
            ),
            const SizedBox(height:30),
            SizedBox(
                width:double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:AppColors.primary,
                        padding:
                        const EdgeInsets.symmetric(vertical:15),
                        shape:RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                        ),
                    ),
                    onPressed:(){
                        // rescheduleAppointment()
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DigitalTokenDetailsScreen(
                                    appointmentId: "",
                                ),
                            ),
                        );
                        ScaffoldMessenger.of(context)
                        .showSnackBar(
                            const SnackBar(
                                content:Text(
                                "Appointment rescheduled successfully",
                                ),
                            ),
                        );
                    },
                    child: const Text(
                        "Confirm Reschedule",
                        style:TextStyle(
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

  Widget _appointmentCard(){
    return Container(
        padding:const EdgeInsets.all(16),
        decoration:BoxDecoration(
            color:Colors.white,
            borderRadius:BorderRadius.circular(16),
        ),
        child:Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children:[
                const Text(
                    "Current Appointment",
                    style:TextStyle(
                        fontSize:16,
                        fontWeight:FontWeight.bold,
                    ),
                ),
                const SizedBox(height:12),
                _detail(
                    "Hospital",
                    widget.hospital,
                ),
                 _detail(
                    "Clinic",
                    widget.clinic,
                ),
                _detail(
                    "Doctor",
                    widget.doctor,
                ),
                _detail(
                    "Date",
                    widget.date,
                ),
                 _detail(
                    "Time",
                    widget.time,
                ),
            ],
        ),
    );
  }
  Widget _detail(String title,String value){
    return Padding(
        padding:
        const EdgeInsets.symmetric(vertical:5),
        child:Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children:[
                Text(
                    title,
                    style:const TextStyle(
                        color:Colors.grey,
                    ),

                ),
                Text(
                    value,
                    style:const TextStyle(
                        fontWeight:FontWeight.w500,
                    ),
                ),
            ],
        ),
    );
  }
}