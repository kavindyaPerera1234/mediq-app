import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'appointment_details_screen.dart';
import '../../patient_appointment_scheduling_module1/screens/caregiver_setup_screen.dart';


class MyAppointmentsScreen extends StatefulWidget {

  const MyAppointmentsScreen({
    super.key,
  });


  @override
  State<MyAppointmentsScreen> createState() =>
      _MyAppointmentsScreenState();

}



class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {


  int selectedTab = 0;


  final List<String> tabs = [
    "Upcoming",
    "Completed",
    "Cancelled",
  ];



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

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [


            Text(

              "My Appointments",

              style: TextStyle(

                color: AppColors.textPrimary,

                fontWeight: FontWeight.bold,

                fontSize:18,

              ),

            ),



            Text(

              "Manage your OPD visits",

              style: TextStyle(

                color: AppColors.textSecondary,

                fontSize:12,

              ),

            ),


          ],

        ),

      ),





      body: Column(

        children: [



          // Tabs

          Container(

            color: Colors.white,


            child: Row(

              mainAxisAlignment:
              MainAxisAlignment.spaceAround,


              children: List.generate(

                tabs.length,


                    (index){


                  bool active =
                      selectedTab == index;



                  return GestureDetector(


                    onTap: (){


                      setState((){

                        selectedTab = index;

                      });


                    },


                    child: Container(

                      padding:
                      const EdgeInsets.symmetric(
                        vertical:14,
                      ),


                      decoration: BoxDecoration(

                        border: Border(

                          bottom: BorderSide(

                            color: active
                                ? AppColors.primary
                                : Colors.transparent,


                            width:2,

                          ),

                        ),

                      ),



                      child: Text(

                        tabs[index],


                        style: TextStyle(

                          color: active
                              ? AppColors.primary
                              : Colors.grey,


                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,

                        ),

                      ),

                    ),

                  );

                },

              ),

            ),

          ),





          Expanded(


            child: Padding(

              padding:
              const EdgeInsets.all(16),



              child: Column(


                children: [



                  Expanded(


                    child: ListView(


                      children: [



                        if(selectedTab == 0)...[



                          appointmentCard(

                            hospital:
                            "National Hospital of Sri Lanka",


                            clinic:
                            "General Medicine OPD",


                            date:
                            "Today, 15 Sep 2026",


                            time:
                            "8:30 AM - 9:00 AM",


                            token:
                            "A-024",


                            status:
                            "CONFIRMED",


                            color:
                            Colors.green,

                          ),





                          appointmentCard(

                            hospital:
                            "Colombo South Teaching Hospital",


                            clinic:
                            "Cardiology Clinic",


                            date:
                            "Wed, 18 Sep 2026",


                            time:
                            "10:00 AM - 10:30 AM",


                            token:
                            "C-108",


                            status:
                            "WAITING",


                            color:
                            Colors.orange,

                          ),



                        ],




                        if(selectedTab != 0)


                          Padding(

                            padding:
                            const EdgeInsets.only(top:100),


                            child: Center(

                              child: Text(

                                "No appointments found",


                                style: TextStyle(

                                  color:
                                  AppColors.textSecondary,

                                ),

                              ),

                            ),

                          ),


                      ],

                    ),

                  ),





                  const SizedBox(height:15),





                  SizedBox(


                    width: double.infinity,


                    height:52,


                    child: ElevatedButton(


                      style:
                      ElevatedButton.styleFrom(


                        backgroundColor:
                        AppColors.primary,


                        shape:
                        RoundedRectangleBorder(


                          borderRadius:
                          BorderRadius.circular(12),


                        ),

                      ),



                      onPressed: (){


                        Navigator.push(


                          context,


                          MaterialPageRoute(


                            builder:(context)=>

                            const CaregiverSetupScreen(),


                          ),


                        );


                      },



                      child: const Text(


                        "Book New Appointment",


                        style: TextStyle(

                          color: Colors.white,

                          fontWeight: FontWeight.bold,

                          fontSize:15,

                        ),

                      ),


                    ),

                  ),



                ],


              ),

            ),

          ),


        ],


      ),

    );

  }






  Widget appointmentCard({


    required String hospital,

    required String clinic,

    required String date,

    required String time,

    required String token,

    required String status,

    required Color color,


  }){


    return GestureDetector(


      onTap: (){


        Navigator.push(


          context,


          MaterialPageRoute(


            builder:(context)=>

            const AppointmentDetailsScreen(),


          ),


        );


      },



      child: Container(


        margin:
        const EdgeInsets.only(bottom:12),


        padding:
        const EdgeInsets.all(14),



        decoration: BoxDecoration(


          color: Colors.white,


          borderRadius:
          BorderRadius.circular(12),


          border: Border.all(

            color:
            Colors.grey.shade200,

          ),


        ),




        child: Column(


          crossAxisAlignment:
          CrossAxisAlignment.start,



          children: [



            Row(


              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,



              children: [



                Expanded(


                  child: Text(


                    hospital,


                    style:
                    const TextStyle(


                      fontWeight:
                      FontWeight.bold,


                      fontSize:13,


                    ),


                  ),


                ),




                Container(


                  padding:
                  const EdgeInsets.symmetric(

                    horizontal:8,

                    vertical:4,

                  ),



                  decoration:
                  BoxDecoration(


                    color:
                    color.withOpacity(0.15),


                    borderRadius:
                    BorderRadius.circular(6),


                  ),




                  child: Text(


                    status,


                    style:
                    TextStyle(


                      color:color,


                      fontSize:10,


                      fontWeight:
                      FontWeight.bold,


                    ),


                  ),


                ),


              ],


            ),




            const SizedBox(height:5),




            Text(


              clinic,


              style: TextStyle(

                color:
                AppColors.textSecondary,


                fontSize:12,


              ),


            ),




            const Divider(),




            Row(


              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,



              children: [



                Column(


                  crossAxisAlignment:
                  CrossAxisAlignment.start,



                  children: [


                    Text(


                      date,


                      style:
                      const TextStyle(

                        fontWeight:
                        FontWeight.w600,

                      ),


                    ),




                    Text(


                      time,


                      style:
                      const TextStyle(

                        fontSize:12,

                      ),


                    ),



                  ],


                ),





                Text.rich(


                  TextSpan(


                    text:"Token: ",


                    children:[



                      TextSpan(


                        text:token,


                        style:TextStyle(


                          color:
                          AppColors.primary,


                          fontWeight:
                          FontWeight.bold,


                        ),


                      ),


                    ],


                  ),


                ),


              ],


            ),



          ],


        ),


      ),


    );


  }


}