import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/patient_bottom_nav_bar.dart';


class AppointmentDetailsScreen extends StatelessWidget {

  const AppointmentDetailsScreen({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,


      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        leading: IconButton(

          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textDark,
          ),

          onPressed: () {

            Navigator.pop(context);

          },

        ),


        title: Text(

          "Appointment Details",

          style: TextStyle(

            color: AppColors.textDark,

            fontWeight: FontWeight.bold,

          ),

        ),

        centerTitle: true,

      ),



      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,


          children: [


            Text(

              "Your Appointment",

              style: TextStyle(

                fontSize: 22,

                fontWeight: FontWeight.bold,

                color: AppColors.textDark,

              ),

            ),



            const SizedBox(height: 20),



            _infoCard(),



            const SizedBox(height: 20),



            _statusCard(),



            const SizedBox(height: 20),



            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(

                  backgroundColor: AppColors.primary,

                  padding: const EdgeInsets.symmetric(

                    vertical: 15,

                  ),

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(12),

                  ),

                ),


                onPressed: () {

                  // Reschedule action later

                },


                child: const Text(

                  "Reschedule Appointment",

                  style: TextStyle(

                    color: Colors.white,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

            ),



            const SizedBox(height: 12),



            SizedBox(

              width: double.infinity,

              child: OutlinedButton(

                style: OutlinedButton.styleFrom(

                  padding: const EdgeInsets.symmetric(

                    vertical: 15,

                  ),

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(12),

                  ),

                ),


                onPressed: () {

                  // Cancel action later

                },


                child: Text(

                  "Cancel Appointment",

                  style: TextStyle(

                    color: AppColors.statusRed,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

            ),


          ],

        ),

      ),



      bottomNavigationBar: PatientBottomNavBar(

        currentIndex: 2,

        onTap: (index) {

        },

      ),

    );

  }





  Widget _infoCard() {


    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(20),


      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

      ),



      child: Column(

        children: [


          _row(

            "Hospital",

            "National Hospital of Sri Lanka",

          ),


          _row(

            "Clinic",

            "General Medicine",

          ),


          _row(

            "Doctor",

            "Dr. Silva",

          ),


          _row(

            "Date",

            "20 October 2026",

          ),


          _row(

            "Time",

            "8:30 AM",

          ),


          _row(

            "Token",

            "A-024",

          ),



        ],

      ),

    );

  }





  Widget _statusCard() {


    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(18),


      decoration: BoxDecoration(

        color: Colors.green.shade50,

        borderRadius: BorderRadius.circular(15),

      ),



      child: Row(

        children: [


          const Icon(

            Icons.check_circle,

            color: Colors.green,

          ),



          const SizedBox(width: 10),



          Text(

            "Appointment Confirmed",

            style: TextStyle(

              color: AppColors.textDark,

              fontWeight: FontWeight.bold,

            ),

          ),


        ],

      ),

    );

  }





  Widget _row(

    String title,

    String value,

  ) {


    return Padding(

      padding: const EdgeInsets.only(

        bottom: 14,

      ),


      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,


        children: [


          Text(

            title,

            style: TextStyle(

              color: Colors.grey[600],

            ),

          ),



          Flexible(

            child: Text(

              value,

              textAlign: TextAlign.right,

              style: TextStyle(

                fontWeight: FontWeight.w600,

                color: AppColors.textDark,

              ),

            ),

          ),


        ],

      ),

    );

  }

}