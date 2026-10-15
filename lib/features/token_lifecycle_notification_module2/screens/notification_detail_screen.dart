import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_colors.dart';

import '../../auth_live_queue_module3/screens/states/rejoin_queue_screen.dart';

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

  bool get _isMissedNotification {
    return notification.type == 'missed_token' ||
        notification.type == 'missed_turn' ||
        notification.type == 'missed';
  }

  Future<String> _getTokenFromDatabase() async {
    try {
      if (notification.tokenNumber != null &&
          notification.tokenNumber!.trim().isNotEmpty) {
        return notification.tokenNumber!.trim();
      }

      final appointmentId =
          notification.appointmentId?.trim() ?? '';

      if (appointmentId.isNotEmpty) {
        final appointmentDoc =
            await FirebaseFirestore.instance
                .collection('appointments')
                .doc(appointmentId)
                .get();

        if (appointmentDoc.exists &&
            appointmentDoc.data() != null) {
          final data = appointmentDoc.data()!;

          final token =
              (data['tokenNumber'] ??
                      data['tokenCode'] ??
                      '')
                  .toString()
                  .trim();

          if (token.isNotEmpty) {
            return token;
          }
        }
      }

      final match = RegExp(
        r'\b[A-Za-z]-\d+\b',
      ).firstMatch(notification.message);

      if (match != null) {
        final token = match.group(0);

        if (token != null &&
            token.trim().isNotEmpty) {
          return token.trim();
        }
      }

      return 'Not available';
    } catch (e) {
      final match = RegExp(
        r'\b[A-Za-z]-\d+\b',
      ).firstMatch(notification.message);

      if (match != null) {
        final token = match.group(0);

        if (token != null &&
            token.trim().isNotEmpty) {
          return token.trim();
        }
      }

      return 'Not available';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
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
        title: Text(
          _appBarTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildScreen(context),
      ),
    );
  }

  String _appBarTitle() {
    if (_isMissedNotification) {
      return 'Token Status';
    }

    return 'Notification';
  }

  Widget _buildScreen(
    BuildContext context,
  ) {
    switch (notification.type) {
      case 'near_turn':
      case 'queue_approaching':
      case 'caregiver_queue_approaching':
        return nearTurn();

      case 'delay':
      case 'delay_broadcast':
      case 'queue_delayed':
        return delay();

      case 'missed_token':
      case 'missed_turn':
      case 'missed':
        return missedToken(context);

      case 'your_turn':
      case 'token_called':
      case 'caregiver_your_turn':
        return yourTurnCalled();

      case 'appointment_confirmed':
        return appointmentConfirmed();

      case 'reminder':
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
              : 'Your Turn is Approaching',
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
            'YOUR TOKEN',
            _value(notification.tokenNumber),
          ),
          const Divider(),
          infoRow(
            Icons.medical_services,
            'NOW SERVING',
            _value(notification.nowServing),
          ),
          const Divider(),
          infoRow(
            Icons.people,
            'PEOPLE AHEAD',
            _value(notification.peopleAhead),
          ),
          const Divider(),
          infoRow(
            Icons.timer,
            'ESTIMATED WAIT',
            _value(notification.estimatedWait),
          ),
          const Divider(),
          infoRow(
            Icons.local_hospital_outlined,
            'HOSPITAL',
            _value(notification.hospitalName),
          ),
          const Divider(),
          infoRow(
            Icons.medical_services_outlined,
            'CLINIC / OPD',
            _value(notification.clinicName),
          ),
          const Divider(),
          infoRow(
            Icons.meeting_room_outlined,
            'OPD ROOM',
            _value(notification.roomNumber),
          ),
        ]),
        const SizedBox(height: 20),
        if (notification.roomNumber != null &&
            notification.roomNumber!
                .trim()
                .isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Text(
              'Please proceed to ${notification.roomNumber}.',
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
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Text(
              notification.title.isNotEmpty
                  ? notification.title
                  : 'OPD Queue Delayed',
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
            'AFFECTED OPD',
            _value(
              notification.affectedOPD ??
                  notification.clinicName,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.timer_outlined,
            'ESTIMATED DELAY',
            _value(notification.delayTime),
          ),
          const Divider(),
          infoRow(
            Icons.confirmation_number,
            'YOUR TOKEN',
            _value(notification.tokenNumber),
          ),
          const Divider(),
          infoRow(
            Icons.meeting_room_outlined,
            'OPD ROOM',
            _value(notification.roomNumber),
          ),
        ]),
      ],
    );
  }

  Widget missedToken(
    BuildContext context,
  ) {
    final token =
        _value(notification.tokenNumber);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(
                0xFFFFE9E9,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(
                  0xFFFFB8B8,
                ),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE53935),
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'You Missed Your Turn',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE53935),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          token == 'Not available'
              ? 'Your token was called, but you were not present at the counter.'
              : 'Your token was called but you were not present at the counter.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7A7A7A),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: const Color(
                0xFFE6EAF0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.03,
                ),
                blurRadius: 8,
                offset:
                    const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  const Text(
                    'YOUR TOKEN',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(
                        0xFF8A94A6,
                      ),
                      fontWeight:
                          FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration:
                        BoxDecoration(
                      color: const Color(
                        0xFFFFE8E8,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(20),
                    ),
                    child: const Text(
                      'MISSED',
                      style: TextStyle(
                        color: Color(
                          0xFFE53935,
                        ),
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                token,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(
                    0xFF344054,
                  ),
                  fontSize: 28,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(
                color:
                    Color(0xFFEEF1F5),
              ),
              const SizedBox(height: 10),
              Text(
                _missedInstructionText(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color:
                      Color(0xFF8A94A6),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_hasMissedAppointmentDetails())
          ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: const Color(
                    0xFFE6EAF0,
                  ),
                ),
              ),
              child: Column(
                children: [
                  if (notification
                              .hospitalName !=
                          null &&
                      notification
                          .hospitalName!
                          .trim()
                          .isNotEmpty)
                    _missedDetailRow(
                      Icons
                          .local_hospital_outlined,
                      'Hospital',
                      notification
                          .hospitalName!,
                    ),
                  if (notification
                              .clinicName !=
                          null &&
                      notification.clinicName!
                          .trim()
                          .isNotEmpty)
                    ...[
                      const Divider(),
                      _missedDetailRow(
                        Icons
                            .medical_services_outlined,
                        'Clinic / OPD',
                        notification
                            .clinicName!,
                      ),
                    ],
                  if (notification
                              .roomNumber !=
                          null &&
                      notification.roomNumber!
                          .trim()
                          .isNotEmpty)
                    ...[
                      const Divider(),
                      _missedDetailRow(
                        Icons
                            .meeting_room_outlined,
                        'OPD Room',
                        notification
                            .roomNumber!,
                      ),
                    ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const RejoinQueueScreen(),
                ),
              );
            },
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primary,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),
            child: const Text(
              'Rejoin Queue',
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              _showContactOpdDialog(
                context,
              );
            },
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  AppColors.primary,
              side: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),
            child: const Text(
              'Contact OPD',
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  String _missedInstructionText() {
    final room =
        notification.roomNumber?.trim();

    if (room != null &&
        room.isNotEmpty) {
      return 'Please contact the OPD counter staff immediately or rejoin the queue below. OPD Room: $room.';
    }

    return 'Please contact the OPD counter staff immediately or rejoin the queue below.';
  }

  bool _hasMissedAppointmentDetails() {
    return (notification.hospitalName !=
                null &&
            notification.hospitalName!
                .trim()
                .isNotEmpty) ||
        (notification.clinicName !=
                null &&
            notification.clinicName!
                .trim()
                .isNotEmpty) ||
        (notification.roomNumber !=
                null &&
            notification.roomNumber!
                .trim()
                .isNotEmpty);
  }

  Widget _missedDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color:
                    Color(0xFF7A8495),
                fontSize: 12,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color:
                    Color(0xFF344054),
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactOpdDialog(
    BuildContext context,
  ) {
    final hospital =
        _value(notification.hospitalName);

    final clinic =
        _value(notification.clinicName);

    final room =
        _value(notification.roomNumber);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons
                    .support_agent_rounded,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Text(
                'Contact OPD',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Please contact the hospital OPD counter for assistance.\n\n'
            'Hospital: $hospital\n'
            'Clinic / OPD: $clinic\n'
            'Room: $room',
            style: const TextStyle(
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget yourTurnCalled() {
    final title =
        notification.title.trim();

    final bool isTokenCalled =
        title
            .toLowerCase()
            .contains('token called');

    final Color alertColor =
        isTokenCalled
            ? Colors.red
            : AppColors.primary;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isTokenCalled
                  ? Colors.red.shade50
                  : Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTokenCalled
                  ? Icons
                      .notifications_active_rounded
                  : Icons.campaign_outlined,
              color: alertColor,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title.isNotEmpty
              ? title
              : 'Your Turn',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: alertColor,
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          notification.message.isEmpty
              ? 'Please proceed to the OPD.'
              : notification.message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(
              0xFF667085,
            ),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: const Color(
                0xFFE6EAF0,
              ),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'YOUR TOKEN',
                style: TextStyle(
                  color: Color(
                    0xFF8A94A6,
                  ),
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              FutureBuilder<String>(
                future:
                    _getTokenFromDatabase(),
                builder:
                    (context, snapshot) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return SizedBox(
                      width: 26,
                      height: 26,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color:
                            alertColor,
                      ),
                    );
                  }

                  final token =
                      snapshot.data ??
                          'Not available';

                  return Text(
                    token,
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          alertColor,
                      fontSize: 30,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),
              Divider(
                color:
                    Colors.grey.shade200,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(
                      color: Colors
                          .blue.shade50,
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .medical_services_outlined,
                      color:
                          AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          'STATUS',
                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFF8A94A6,
                            ),
                            fontSize:
                                10,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          isTokenCalled
                              ? 'Token Called'
                              : 'Your Turn Now',
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF344054,
                            ),
                            fontSize:
                                14,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (notification
                          .roomNumber !=
                      null &&
                  notification
                      .roomNumber!
                      .trim()
                      .isNotEmpty)
                ...[
                  const Divider(
                    height: 28,
                  ),
                  infoRow(
                    Icons
                        .meeting_room_outlined,
                    'OPD ROOM',
                    notification
                        .roomNumber!,
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding:
              const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isTokenCalled
                ? Colors.red.shade50
                : Colors.blue.shade50,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: alertColor,
                size: 21,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  isTokenCalled
                      ? 'Your token has been called. Please proceed to the consultation room as soon as possible.'
                      : 'It is now your turn. Please proceed to the OPD immediately.',
                  style:
                      const TextStyle(
                    color: Color(
                      0xFF344054,
                    ),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight:
                        FontWeight
                            .w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget appointmentConfirmed() {
    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 30,
          backgroundColor:
              Colors.green.shade50,
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
              : 'Appointment Confirmed',
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
            Icons
                .confirmation_number_outlined,
            'YOUR TOKEN',
            _value(
              notification.tokenNumber,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.person_outline,
            'PATIENT',
            _value(
              notification.patientName,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.local_hospital_outlined,
            'HOSPITAL',
            _value(
              notification.hospitalName,
            ),
          ),
          const Divider(),
          infoRow(
            Icons
                .medical_services_outlined,
            'CLINIC / OPD',
            _value(
              notification.clinicName,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.meeting_room_outlined,
            'OPD ROOM',
            _value(
              notification.roomNumber,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.calendar_month_outlined,
            'DATE',
            _value(
              notification
                  .appointmentDate,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.access_time,
            'TIME SLOT',
            _value(
              notification.timeSlot,
            ),
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
          backgroundColor:
              Colors.blue.shade50,
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
              : 'OPD Reminder',
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
            'PATIENT',
            _value(
              notification.patientName,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.local_hospital_outlined,
            'HOSPITAL',
            _value(
              notification.hospitalName,
            ),
          ),
          const Divider(),
          infoRow(
            Icons
                .medical_services_outlined,
            'CLINIC / OPD',
            _value(
              notification.clinicName,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.meeting_room_outlined,
            'OPD ROOM',
            _value(
              notification.roomNumber,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.calendar_today,
            'DATE',
            _value(
              notification
                  .appointmentDate,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.access_time,
            'TIME',
            _value(
              notification.timeSlot,
            ),
          ),
          const Divider(),
          infoRow(
            Icons.confirmation_number,
            'YOUR TOKEN',
            _value(
              notification.tokenNumber,
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: const Text(
            'Please arrive 15 minutes before your appointment time.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget detailCard(
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
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
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
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
            fontWeight:
                FontWeight.bold,
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