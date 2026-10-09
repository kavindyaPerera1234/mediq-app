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

  Set<String> _currentUserIds() {
    final ids = <String>{};

    try {
      final user = AuthService().currentUser;

      if (user != null) {
        if (user.nic != null &&
            user.nic!.trim().isNotEmpty) {
          ids.add(user.nic!.trim());
        }

        if (user.phoneNumber.trim().isNotEmpty) {
          ids.add(user.phoneNumber.trim());
        }

        if (user.userId.trim().isNotEmpty) {
          ids.add(user.userId.trim());
        }
      }
    } catch (_) {}

    return ids;
  }

  bool _belongsToCurrentUser(
    Map<String, dynamic> data,
    Set<String> ids,
  ) {
    if (ids.isEmpty) return true;

    final patientId =
        (data['patientId'] ?? '').toString().trim();

    final patientNic =
        (data['patientNic'] ?? '').toString().trim();

    final userId =
        (data['userId'] ?? '').toString().trim();

    return ids.contains(patientId) ||
        ids.contains(patientNic) ||
        ids.contains(userId);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      _getAppointment() async {
    final firestore = FirebaseFirestore.instance;
    final value = widget.appointmentId.trim();

    // 1. Real Firestore document ID
    if (value.isNotEmpty) {
      final doc = await firestore
          .collection('appointments')
          .doc(value)
          .get();

      if (doc.exists) {
        return doc;
      }

      // 2. Token fallback such as A-001
      final byToken = await firestore
          .collection('appointments')
          .where(
            'tokenCode',
            isEqualTo: value,
          )
          .get();

      if (byToken.docs.isNotEmpty) {
        final userIds = _currentUserIds();

        var tokenDocs = byToken.docs
            .where(
              (doc) => _belongsToCurrentUser(
                doc.data(),
                userIds,
              ),
            )
            .toList();

        if (tokenDocs.isEmpty) {
          tokenDocs = byToken.docs.toList();
        }

        tokenDocs.sort(
          (a, b) => _compareAppointmentDocuments(
            b,
            a,
          ),
        );

        return tokenDocs.first;
      }
    }

    // 3. Current user's latest appointment fallback
    final ids = _currentUserIds();

    if (ids.isEmpty) {
      ids.add('200164801234');
    }

    final userAppointments =
        <String,
            QueryDocumentSnapshot<
                Map<String, dynamic>>>{};

    for (final id in ids) {
      final q1 = await firestore
          .collection('appointments')
          .where(
            'patientId',
            isEqualTo: id,
          )
          .get();

      for (final doc in q1.docs) {
        userAppointments[doc.id] = doc;
      }

      final q2 = await firestore
          .collection('appointments')
          .where(
            'patientNic',
            isEqualTo: id,
          )
          .get();

      for (final doc in q2.docs) {
        userAppointments[doc.id] = doc;
      }

      final q3 = await firestore
          .collection('appointments')
          .where(
            'userId',
            isEqualTo: id,
          )
          .get();

      for (final doc in q3.docs) {
        userAppointments[doc.id] = doc;
      }
    }

    if (userAppointments.isEmpty) {
      return null;
    }

    final sorted = userAppointments.values.toList();

    sorted.sort(
      (a, b) => _compareAppointmentDocuments(
        b,
        a,
      ),
    );

    return sorted.first;
  }

  int _compareAppointmentDocuments(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final aData = a.data();
    final bData = b.data();

    final aCreated =
        _getTimestampValue(aData['createdAt']);

    final bCreated =
        _getTimestampValue(bData['createdAt']);

    if (aCreated != null && bCreated != null) {
      final result =
          aCreated.compareTo(bCreated);

      if (result != 0) return result;
    } else if (aCreated != null) {
      return 1;
    } else if (bCreated != null) {
      return -1;
    }

    final aUpdated =
        _getTimestampValue(aData['updatedAt']);

    final bUpdated =
        _getTimestampValue(bData['updatedAt']);

    if (aUpdated != null && bUpdated != null) {
      final result =
          aUpdated.compareTo(bUpdated);

      if (result != 0) return result;
    }

    final aDate =
        (aData['appointmentDate'] ?? '')
            .toString();

    final bDate =
        (bData['appointmentDate'] ?? '')
            .toString();

    final dateResult =
        aDate.compareTo(bDate);

    if (dateResult != 0) {
      return dateResult;
    }

    return (aData['timeSlot'] ?? '')
        .toString()
        .compareTo(
          (bData['timeSlot'] ?? '')
              .toString(),
        );
  }

  DateTime? _getTimestampValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String &&
        value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
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

      final backgroundPaint =
          Paint()..color = Colors.white;

      canvas.drawRect(
        const Rect.fromLTWH(
          0,
          0,
          imageSize,
          imageSize,
        ),
        backgroundPaint,
      );

      canvas.save();

      canvas.translate(
        qrPosition,
        qrPosition,
      );

      qrPainter.paint(
        canvas,
        const Size(
          qrSize,
          qrSize,
        ),
      );

      canvas.restore();

      final picture =
          recorder.endRecording();

      final image =
          await picture.toImage(
        imageSize.toInt(),
        imageSize.toInt(),
      );

      final byteData =
          await image.toByteData(
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
        ext: 'png',
        mimeType: MimeType.png,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'QR code saved successfully.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
          DocumentSnapshot<
              Map<String, dynamic>>?>(
        future: _getAppointment(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(24),
                child: Text(
                  'Unable to load appointment details.',
                  textAlign:
                      TextAlign.center,
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

          final data =
              snapshot.data!.data()!;

          final tokenCode =
              (data['tokenCode'] ??
                      data['tokenNumber'] ??
                      '')
                  .toString();

          final patientName =
              (data['patientName'] ?? '')
                  .toString();

          final hospitalName =
              (data['hospitalName'] ?? '')
                  .toString();

          final clinicName =
              (data['departmentName'] ??
                      data['clinicName'] ??
                      '')
                  .toString();

          // OPD ROOM
          final roomNumber =
              (data['roomNumber'] ?? '')
                  .toString()
                  .trim();

          final appointmentDate =
              (data['appointmentDate'] ?? '')
                  .toString();

          final timeSlot =
              (data['timeSlot'] ?? '')
                  .toString();

          final status =
              (data['status'] ?? 'confirmed')
                  .toString();

          final qrData = _createQrData(
            tokenCode: tokenCode,
            patientName: patientName,
            appointmentDate:
                appointmentDate,
            timeSlot: timeSlot,
          );

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              children: [
                // TOKEN CARD
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color:
                            Colors.black12,
                        blurRadius: 8,
                        offset:
                            Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR DIGITAL TOKEN',
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        tokenCode.isEmpty
                            ? 'N/A'
                            : tokenCode,
                        style:
                            const TextStyle(
                          color:
                              AppColors.primary,
                          fontSize: 46,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.green
                              .shade100,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Text(
                          status
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors
                                .green
                                .shade700,
                            fontSize: 11,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // APPOINTMENT DETAILS
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          const Text(
                            'Appointment Details',
                            style: TextStyle(
                              color: AppColors
                                  .textPrimary,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton
                                .styleFrom(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              tapTargetSize:
                                  MaterialTapTargetSize
                                      .shrinkWrap,
                            ),
                            icon: const Icon(
                              Icons
                                  .arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors
                                  .primary,
                            ),
                            label: const Text(
                              'Manage Visit',
                              style: TextStyle(
                                color: AppColors
                                    .primary,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          AppointmentDetailsScreen(
                                    appointmentId:
                                        snapshot
                                            .data!.id,
                                    token:
                                        tokenCode,
                                    patientName:
                                        patientName,
                                    hospitalName:
                                        hospitalName,
                                    clinic:
                                        clinicName,
                                    date:
                                        appointmentDate,
                                    time:
                                        timeSlot,
                                    status:
                                        status,
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
                        Icons
                            .local_hospital_outlined,
                        'Hospital',
                        hospitalName,
                      ),

                      _detailRow(
                        Icons
                            .medical_services_outlined,
                        'Clinic',
                        clinicName,
                      ),

                      // OPD ROOM
                      _detailRow(
                        Icons
                            .meeting_room_outlined,
                        'OPD Room',
                        roomNumber.isEmpty
                            ? 'Not available'
                            : roomNumber,
                      ),

                      _detailRow(
                        Icons
                            .calendar_today_outlined,
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
                        child:
                            OutlinedButton
                                .icon(
                          icon: const Icon(
                            Icons
                                .edit_calendar_rounded,
                            size: 18,
                            color: AppColors
                                .primary,
                          ),
                          label: const Text(
                            'Manage Appointment (Reschedule / Cancel)',
                            style: TextStyle(
                              color: AppColors
                                  .primary,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 13,
                            ),
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 12,
                            ),
                            side:
                                const BorderSide(
                              color: AppColors
                                  .primary,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                10,
                              ),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AppointmentDetailsScreen(
                                  appointmentId:
                                      snapshot
                                          .data!.id,
                                  token:
                                      tokenCode,
                                  patientName:
                                      patientName,
                                  hospitalName:
                                      hospitalName,
                                  clinic:
                                      clinicName,
                                  date:
                                      appointmentDate,
                                  time:
                                      timeSlot,
                                  status:
                                      status,
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

                // QR CARD
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Digital Token QR',
                        style: TextStyle(
                          color: AppColors
                              .textPrimary,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      const Text(
                        'Show this QR code when required at the hospital.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .all(14),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey
                                .shade300,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version:
                              QrVersions.auto,
                          size: 210,
                          backgroundColor:
                              Colors.white,
                          gapless: true,
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      Text(
                        tokenCode,
                        style:
                            const TextStyle(
                          color:
                              AppColors.primary,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      SizedBox(
                        width: double.infinity,
                        child:
                            ElevatedButton
                                .icon(
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                AppColors
                                    .primary,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const LiveQueueMainScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons
                                .format_list_bulleted_rounded,
                            color:
                                Colors.white,
                          ),
                          label: const Text(
                            'Track Live Queue',
                            style: TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      SizedBox(
                        width: double.infinity,
                        child:
                            ElevatedButton
                                .icon(
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                AppColors
                                    .primary,
                            disabledBackgroundColor:
                                Colors.grey
                                    .shade400,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),
                          onPressed:
                              _isDownloading
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
                                    strokeWidth:
                                        2,
                                    color: Colors
                                        .white,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .download,
                                  color: Colors
                                      .white,
                                ),
                          label: Text(
                            _isDownloading
                                ? 'Saving QR Code...'
                                : 'Download QR Code',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      SizedBox(
                        width: double.infinity,
                        child:
                            OutlinedButton
                                .icon(
                          onPressed: () {
                            Navigator.pop(
                              context,
                            );
                          },
                          icon: const Icon(
                            Icons
                                .calendar_month_outlined,
                            color: AppColors
                                .primary,
                          ),
                          label: const Text(
                            'Back to Home ',
                            style: TextStyle(
                              color: AppColors
                                  .primary,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 15,
                            ),
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                            side:
                                const BorderSide(
                              color: AppColors
                                  .primary,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
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

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.blue.shade50,
                    borderRadius:
                        BorderRadius
                            .circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color:
                            AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Keep your digital token available when visiting the hospital.',
                          style: TextStyle(
                            color: AppColors
                                .textPrimary,
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
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
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
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: AppColors
                        .textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value.isEmpty
                      ? 'Not available'
                      : value,
                  style:
                      const TextStyle(
                    color: AppColors
                        .textPrimary,
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