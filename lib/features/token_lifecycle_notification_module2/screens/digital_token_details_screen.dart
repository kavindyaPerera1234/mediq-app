import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';
import '../../auth_live_queue_module3/screens/queue/live_queue_main_screen.dart';
import 'appointment_details_screen.dart';
import 'my_appointments_screen.dart';

class DigitalTokenDetailsScreen extends StatefulWidget {
  final String appointmentId;

  const DigitalTokenDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<DigitalTokenDetailsScreen> createState() =>
      _DigitalTokenDetailsScreenState();
}

class _DigitalTokenDetailsScreenState
    extends State<DigitalTokenDetailsScreen> {
  bool _isDownloading = false;

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      _getAppointment() async {
    if (widget.appointmentId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();
      if (doc.exists) return doc;

      final byToken = await FirebaseFirestore.instance
          .collection('appointments')
          .where('tokenCode', isEqualTo: widget.appointmentId)
          .limit(1)
          .get();
      if (byToken.docs.isNotEmpty) return byToken.docs.first;
    }

    final ids = <String>[];
    final user = AuthService().currentUser;
    if (user != null) {
      if (user.nic != null && user.nic!.isNotEmpty) ids.add(user.nic!);
      if (user.phoneNumber.isNotEmpty) ids.add(user.phoneNumber);
      if (user.userId.isNotEmpty) ids.add(user.userId);
    }
    if (ids.isEmpty) ids.add('200164801234');

    for (final id in ids) {
      final q1 = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: id)
          .get();
      if (q1.docs.isNotEmpty) {
        final sorted = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(q1.docs)
          ..sort((a, b) => (b.data()['appointmentDate'] ?? '').toString().compareTo((a.data()['appointmentDate'] ?? '').toString()));
        return sorted.first;
      }

      final q2 = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientNic', isEqualTo: id)
          .get();
      if (q2.docs.isNotEmpty) {
        final sorted = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(q2.docs)
          ..sort((a, b) => (b.data()['appointmentDate'] ?? '').toString().compareTo((a.data()['appointmentDate'] ?? '').toString()));
        return sorted.first;
      }
    }
    return null;
  }

  String _createQrData({
    required String tokenCode,
    required String patientName,
    required String appointmentDate,
    required String timeSlot,
  }) {
    return '''
MediQ Appointment
Token: $tokenCode
Patient: $patientName
Date: $appointmentDate
Time: $timeSlot
''';
  }

  Future<void> _downloadQrCode({
    required String tokenCode,
    required String patientName,
    required String appointmentDate,
    required String timeSlot,
  }) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final qrData = _createQrData(
        tokenCode: tokenCode,
        patientName: patientName,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
      );

      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      const double imageSize = 700;
      const double qrSize = 500;
      const double qrPosition = 100;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White background
      final backgroundPaint = Paint()
        ..color = Colors.white;

      canvas.drawRect(
        const Rect.fromLTWH(
          0,
          0,
          imageSize,
          imageSize,
        ),
        backgroundPaint,
      );

      // Put QR in the center with white margin.
      canvas.save();

      canvas.translate(
        qrPosition,
        qrPosition,
      );

      // qr_flutter expects Size here.
      qrPainter.paint(
        canvas,
        const Size(
          qrSize,
          qrSize,
        ),
      );

      canvas.restore();

      final picture = recorder.endRecording();

      final image = await picture.toImage(
        imageSize.toInt(),
        imageSize.toInt(),
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception(
          'Unable to generate QR image.',
        );
      }

      final Uint8List pngBytes =
          byteData.buffer.asUint8List();

      await FileSaver.instance.saveFile(
        name: 'MediQ_$tokenCode',
        bytes: pngBytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'QR code saved successfully.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save QR code.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Digital Token',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: FutureBuilder<
          DocumentSnapshot<Map<String, dynamic>>?>(
        future: _getAppointment(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load appointment details.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Appointment not found.',
              ),
            );
          }

          final data = snapshot.data!.data()!;

          final tokenCode =
              (data['tokenCode'] ?? '').toString();

          final patientName =
              (data['patientName'] ?? '').toString();

          final hospitalName =
              (data['hospitalName'] ?? '').toString();

          final clinicName =
              (data['departmentName'] ?? '').toString();

          final appointmentDate =
              (data['appointmentDate'] ?? '').toString();

          final timeSlot =
              (data['timeSlot'] ?? '').toString();

          final status =
              (data['status'] ?? 'confirmed').toString();

          final qrData = _createQrData(
            tokenCode: tokenCode,
            patientName: patientName,
            appointmentDate: appointmentDate,
            timeSlot: timeSlot,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                // ==========================
                // TOKEN CARD
                // ==========================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [

                      const Text(
                        'YOUR DIGITAL TOKEN',
                        style: TextStyle(
                          color:
                              AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        tokenCode.isEmpty
                            ? 'N/A'
                            : tokenCode,

                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 46,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),

                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color:
                                Colors.green.shade700,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================
                // APPOINTMENT DETAILS
                // ==========================

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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Appointment Details',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                            label: const Text(
                              'Manage Visit',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AppointmentDetailsScreen(
                                    appointmentId: snapshot.data!.id,
                                    token: tokenCode,
                                    patientName: patientName,
                                    hospitalName: hospitalName,
                                    clinic: clinicName,
                                    date: appointmentDate,
                                    time: timeSlot,
                                    status: status,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _detailRow(
                        Icons.person_outline,
                        'Patient',
                        patientName,
                      ),

                      _detailRow(
                        Icons.local_hospital_outlined,
                        'Hospital',
                        hospitalName,
                      ),

                      _detailRow(
                        Icons.medical_services_outlined,
                        'Clinic',
                        clinicName,
                      ),

                      _detailRow(
                        Icons.calendar_today_outlined,
                        'Date',
                        appointmentDate,
                      ),

                      _detailRow(
                        Icons.access_time,
                        'Time',
                        timeSlot,
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.primary),
                          label: const Text(
                            'Manage Appointment (Reschedule / Cancel)',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppointmentDetailsScreen(
                                  appointmentId: snapshot.data!.id,
                                  token: tokenCode,
                                  patientName: patientName,
                                  hospitalName: hospitalName,
                                  clinic: clinicName,
                                  date: appointmentDate,
                                  time: timeSlot,
                                  status: status,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================
                // QR CODE CARD
                // ==========================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),

                  child: Column(
                    children: [

                      const Text(
                        'Digital Token QR',
                        style: TextStyle(
                          color:
                              AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Show this QR code when required at the hospital.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // QR CODE
                      Container(
                        padding:
                            const EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                          borderRadius:
                              BorderRadius.circular(16),
                        ),

                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 210,
                          backgroundColor:
                              Colors.white,
                          gapless: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        tokenCode,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==========================
                      // TRACK LIVE QUEUE CTA
                      // ==========================
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LiveQueueMainScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.format_list_bulleted_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Track Live Queue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==========================
                      // DOWNLOAD BUTTON
                      // ==========================

                      SizedBox(
                        width: double.infinity,

                        child:
                            ElevatedButton.icon(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.primary,

                            disabledBackgroundColor:
                                Colors.grey.shade400,

                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),

                          onPressed: _isDownloading
                              ? null
                              : () {
                                  _downloadQrCode(
                                    tokenCode:
                                        tokenCode,
                                    patientName:
                                        patientName,
                                    appointmentDate:
                                        appointmentDate,
                                    timeSlot:
                                        timeSlot,
                                  );
                                },

                          icon: _isDownloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.download,
                                  color:
                                      Colors.white,
                                ),

                          label: Text(
                            _isDownloading
                                ? 'Saving QR Code...'
                                : 'Download QR Code',
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==========================
                      // BACK TO MY APPOINTMENTS
                      // ==========================

                      SizedBox(
                        width: double.infinity,

                        child:
                            OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MyAppointmentsScreen(
                                  initialTab: 0,
                                ),
                              ),
                              (route) => false,
                            );
                          },

                          icon: const Icon(
                            Icons
                                .calendar_month_outlined,
                            color:
                                AppColors.primary,
                          ),

                          label: const Text(
                            'Back to My Appointments',
                            style: TextStyle(
                              color:
                                  AppColors.primary,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          style:
                              OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),

                            side:
                                const BorderSide(
                              color:
                                  AppColors.primary,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================
                // INFORMATION
                // ==========================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Keep your digital token available when visiting the hospital.',
                          style: TextStyle(
                            color:
                                AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius:
                  BorderRadius.circular(10),
            ),

            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
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
                  value.isEmpty
                      ? 'Not available'
                      : value,

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