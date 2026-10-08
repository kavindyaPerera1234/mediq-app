import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
  });

  @override
  State<QrScannerScreen> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState
    extends State<QrScannerScreen> {
  final MobileScannerController _controller =
      MobileScannerController();

  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) {
    if (_isScanned) return;

    if (capture.barcodes.isEmpty) return;

    final String? value =
        capture.barcodes.first.rawValue;

    if (value == null || value.trim().isEmpty) {
      return;
    }

    _isScanned = true;

    _controller.stop();

    final appointment =
        _parseAppointmentData(value);

    if (appointment == null) {
      setState(() {
        _isScanned = false;
      });

      _controller.start();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid MediQ appointment QR code.',
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QrAppointmentResultScreen(
          appointment: appointment,
        ),
      ),
    ).then((_) {
      if (!mounted) return;

      setState(() {
        _isScanned = false;
      });

      _controller.start();
    });
  }

  Map<String, String>? _parseAppointmentData(
    String value,
  ) {
    try {
      final lines = value
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      String token = '';
      String patient = '';
      String date = '';
      String time = '';

      for (final line in lines) {
        if (line.startsWith('Token:')) {
          token =
              line.substring(6).trim();
        } else if (line.startsWith('Patient:')) {
          patient =
              line.substring(8).trim();
        } else if (line.startsWith('Date:')) {
          date =
              line.substring(5).trim();
        } else if (line.startsWith('Time:')) {
          time =
              line.substring(5).trim();
        }
      }

      if (token.isEmpty ||
          patient.isEmpty ||
          date.isEmpty ||
          time.isEmpty) {
        return null;
      }

      return {
        'token': token,
        'patient': patient,
        'date': date,
        'time': time,
      };
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Scan Digital Token',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [

          MobileScanner(
            controller: _controller,
            onDetect: _handleScan,
          ),

          // DARK OVERLAY
          IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),

          // SCANNER FRAME
          Center(
            child: Container(
              width: 270,
              height: 270,

              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius:
                    BorderRadius.circular(24),
              ),
            ),
          ),

          // TOP MESSAGE
          Positioned(
            top: 35,
            left: 30,
            right: 30,
            child: Column(
              children: const [
                Text(
                  'Scan Digital Token',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Place the QR code inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM INFORMATION
          Positioned(
            left: 30,
            right: 30,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: const Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primary,
                    size: 30,
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Scan a MediQ digital token to view the appointment details.',
                      style: TextStyle(
                        color:
                            AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
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
}


// =====================================================
// QR RESULT SCREEN
// =====================================================

class QrAppointmentResultScreen
    extends StatelessWidget {
  final Map<String, String> appointment;

  const QrAppointmentResultScreen({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final token =
        appointment['token'] ?? '';

    final patient =
        appointment['patient'] ?? '';

    final date =
        appointment['date'] ?? '';

    final time =
        appointment['time'] ?? '';

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

        title: const Text(
          'Appointment',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // VERIFIED CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                children: [

                  Container(
                    width: 64,
                    height: 64,

                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      Icons.check_rounded,
                      color:
                          Colors.green.shade700,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Appointment Verified',
                    style: TextStyle(
                      color:
                          AppColors.textPrimary,
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'MediQ Digital Token',
                    style: TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TOKEN CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blue.shade100,
                ),
              ),

              child: Column(
                children: [

                  const Text(
                    'TOKEN NUMBER',
                    style: TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    token,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 48,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DETAILS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    'Appointment Details',
                    style: TextStyle(
                      color:
                          AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _detailRow(
                    Icons.person_outline,
                    'Patient',
                    patient,
                  ),

                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Date',
                    date,
                  ),

                  _detailRow(
                    Icons.access_time,
                    'Time',
                    time,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // SUCCESS MESSAGE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius:
                    BorderRadius.circular(14),
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Icon(
                    Icons.verified_outlined,
                    color:
                        Colors.green.shade700,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'This digital token has been successfully scanned.',
                      style: TextStyle(
                        color:
                            Colors.green.shade800,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // DONE BUTTON
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),

                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),

      child: Row(
        children: [

          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius:
                  BorderRadius.circular(10),
            ),

            child: Icon(
              icon,
              color: AppColors.primary,
              size: 21,
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
                  style: const TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    color:
                        AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
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