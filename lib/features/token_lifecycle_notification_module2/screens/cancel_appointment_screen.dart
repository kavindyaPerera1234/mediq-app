import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../services/appointment_service.dart';
import 'my_appointments_screen.dart';

class CancelAppointmentScreen extends StatefulWidget {
  final String appointmentId;
  final String hospitalName;
  final String clinic;
  final String date;
  final String time;
  final String token;
  final String patientName;

  const CancelAppointmentScreen({
    super.key,
    required this.appointmentId,
    required this.hospitalName,
    required this.clinic,
    required this.date,
    required this.time,
    required this.token,
    required this.patientName,
  });

  @override
  State<CancelAppointmentScreen> createState() =>
      _CancelAppointmentScreenState();
}

class _CancelAppointmentScreenState
    extends State<CancelAppointmentScreen> {
  final AppointmentService _appointmentService =
      AppointmentService();

  bool _isCancelling = false;

  Future<void> _cancelAppointment() async {
    if (_isCancelling) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await _appointmentService.cancelAppointment(
        widget.appointmentId,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyAppointmentsScreen(
            initialTab: 2,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to cancel appointment. Please try again.',
          ),
        ),
      );
    }
  }

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
          onPressed: _isCancelling
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),
        title: const Text(
          'Cancel Appointment',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // WARNING CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Cancel this appointment?',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action cannot be undone. '
                    'You will lose your token (${widget.token}) '
                    'and need to book a new appointment.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // APPOINTMENT SUMMARY
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'APPOINTMENT SUMMARY',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  summaryRow(
                    'Patient',
                    widget.patientName,
                  ),

                  summaryRow(
                    'Hospital',
                    widget.hospitalName,
                  ),

                  summaryRow(
                    'OPD Unit',
                    widget.clinic,
                  ),

                  summaryRow(
                    'Date & Time',
                    '${widget.date} - ${widget.time}',
                  ),

                  summaryRow(
                    'Token',
                    widget.token,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // CANCEL BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.shade200,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed:
                    _isCancelling ? null : _cancelAppointment,
                child: _isCancelling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Yes, Cancel Appointment',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 10),

            // KEEP APPOINTMENT
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isCancelling
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: const Text(
                  'Keep Appointment',
                  style: TextStyle(
                    color: AppColors.primary,
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

  Widget summaryRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}