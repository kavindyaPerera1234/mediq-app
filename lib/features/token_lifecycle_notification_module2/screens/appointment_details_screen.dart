import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'assisted_queue_setup_screen.dart';
import 'cancel_appointment_screen.dart';
import 'digital_token_details_screen.dart';
import 'reschedule_appointment_screen.dart';
import '../../auth_live_queue_module3/screens/queue/live_queue_main_screen.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;
  final String token;
  final String patientName;
  final String hospitalName;
  final String clinic;
  final String date;
  final String time;
  final String status;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
    required this.token,
    required this.patientName,
    required this.hospitalName,
    required this.clinic,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Appointment Details",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Ref No: $appointmentId",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: [
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            "YOUR TOKEN",
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  AppColors.textSecondary,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            token,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),

                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 25),

                  detailItem(
                    Icons.person_outline,
                    "PATIENT",
                    patientName,
                  ),

                  detailItem(
                    Icons.local_hospital_outlined,
                    "GOVERNMENT HOSPITAL",
                    hospitalName,
                  ),

                  detailItem(
                    Icons.medical_services_outlined,
                    "CLINIC / OPD",
                    clinic,
                  ),

                  detailItem(
                    Icons.calendar_month_outlined,
                    "DATE",
                    date,
                  ),

                  detailItem(
                    Icons.access_time,
                    "TIME SLOT",
                    time,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.people_outline,
                  color: Colors.white,
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LiveQueueMainScreen(),
                    ),
                  );
                },

                label: const Text(
                  "View Live Queue",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Digital Token & QR Code Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DigitalTokenDetailsScreen(
                        appointmentId: appointmentId,
                      ),
                    ),
                  );
                },
                label: const Text(
                  "View Digital Token & QR Code",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Assisted Queue & Caregiver Alert Setup
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.accessibility_new_rounded,
                  color: Color(0xFF0D9488),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssistedQueueSetupScreen(
                        appointmentId: appointmentId,
                      ),
                    ),
                  );
                },
                label: const Text(
                  "Assisted Queue & Caregiver Alert",
                  style: TextStyle(
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.calendar_month,
                  color: AppColors.primary,
                ),

                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),

                  side: const BorderSide(
                    color: AppColors.primary,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                onPressed: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) =>
                          RescheduleAppointmentScreen(
                        appointmentId: appointmentId,
                        hospital: hospitalName,
                        clinic: clinic,
                        doctor: "Not Assigned",
                        date: date,
                        time: time,
                      ),
                    ),
                  );
                },

                label: const Text(
                  "Reschedule Appointment",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),

                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),

                  side: const BorderSide(
                    color: Colors.red,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                onPressed: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) =>
                          CancelAppointmentScreen(
                        appointmentId: appointmentId,
                        hospitalName: hospitalName,
                        clinic: clinic,
                        date: date,
                        time: time,
                        token: token,
                        patientName: patientName,
                      ),
                    ),
                  );
                },

                label: const Text(
                  "Cancel Appointment",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),

            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius:
                  BorderRadius.circular(8),
            ),

            child: Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        AppColors.textSecondary,
                  ),
                ),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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