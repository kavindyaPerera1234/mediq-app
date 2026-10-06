import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'digital_token_details_screen.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
  final String appointmentId;
  final String hospital;
  final String clinic;
  final String doctor;
  final String date;
  final String time;

  const RescheduleAppointmentScreen({
    super.key,
    this.appointmentId = '',
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
  late DateTime selectedDate;
  late String selectedTime;

  bool isSaving = false;

  // Same time slots used by the existing Module 2 rescheduling UI.
  final List<Map<String, String>> timeSlots = [
    {
      'id': 'slot_1',
      'startTime': '08:00',
      'endTime': '09:00',
      'displayTime': '08:00 - 09:00 AM',
    },
    {
      'id': 'slot_2',
      'startTime': '09:00',
      'endTime': '10:00',
      'displayTime': '09:00 - 10:00 AM',
    },
    {
      'id': 'slot_3',
      'startTime': '10:00',
      'endTime': '11:00',
      'displayTime': '10:00 - 11:00 AM',
    },
    {
      'id': 'slot_4',
      'startTime': '11:00',
      'endTime': '12:00',
      'displayTime': '11:00 - 12:00 PM',
    },
    {
      'id': 'slot_5',
      'startTime': '12:00',
      'endTime': '13:00',
      'displayTime': '12:00 - 01:00 PM',
    },
    {
      'id': 'slot_6',
      'startTime': '13:00',
      'endTime': '14:00',
      'displayTime': '01:00 - 02:00 PM',
    },
  ];

  @override
  void initState() {
    super.initState();

    selectedDate = _parseDate(widget.date);

    selectedTime = widget.time.isNotEmpty
        ? widget.time
        : timeSlots.first['displayTime']!;
  }

  // ============================================================
  // DATE
  // ============================================================

  DateTime _parseDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed != null) {
      return parsed;
    }

    final parts = value.split(RegExp(r'[/\\\-. ]'));

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${days[date.weekday - 1]}, '
        '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _chooseDate() async {
    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final initialDate = selectedDate.isBefore(todayOnly)
        ? todayOnly
        : selectedDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: todayOnly,
      lastDate: DateTime(2027, 12, 31),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      selectedDate = pickedDate;
    });
  }

  // ============================================================
  // GENERATE NEXT TOKEN
  //
  // This follows the same database-based logic:
  // 1. appointment_slots -> bookedCount
  // 2. If slot document does not exist, count appointments
  // 3. Generate A-001, A-002, A-003...
  //
  // Module 1 files are NOT modified.
  // ============================================================

  Future<String> _generateNextTokenCode({
    required String departmentId,
    required String appointmentDate,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final slotDocId =
          '${departmentId}_$appointmentDate';

      final slotSnap = await firestore
          .collection('appointment_slots')
          .doc(slotDocId)
          .get()
          .timeout(
            const Duration(seconds: 5),
          );

      int nextSeq = 1;

      if (slotSnap.exists &&
          slotSnap.data() != null) {
        final data = slotSnap.data()!;

        final bookedCount = data['bookedCount'];

        if (bookedCount is num) {
          nextSeq = bookedCount.toInt() + 1;
        }
      } else {
        final querySnap = await firestore
            .collection('appointments')
            .where(
              'departmentId',
              isEqualTo: departmentId,
            )
            .where(
              'appointmentDate',
              isEqualTo: appointmentDate,
            )
            .get()
            .timeout(
              const Duration(seconds: 5),
            );

        final validDocs = querySnap.docs.where((doc) {
          final data = doc.data();

          final status =
              (data['status'] ?? '').toString().toLowerCase();

          return status != 'cancelled';
        }).toList();

        nextSeq = validDocs.length + 1;
      }

      return 'A-${nextSeq.toString().padLeft(3, '0')}';
    } catch (e) {
      // Do not silently break the reschedule flow.
      // Re-throw so the user sees the actual problem.
      throw Exception(
        'Unable to generate the new token: $e',
      );
    }
  }

  // ============================================================
  // CONFIRM RESCHEDULE
  // ============================================================

  Future<void> _confirmReschedule() async {
    if (isSaving) {
      return;
    }

    if (widget.appointmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Appointment ID is missing.',
          ),
        ),
      );

      return;
    }

    if (selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a time slot.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      final appointmentRef = firestore
          .collection('appointments')
          .doc(widget.appointmentId);

      // --------------------------------------------------------
      // 1. Read the existing appointment from Firestore
      // --------------------------------------------------------

      final appointmentSnapshot =
          await appointmentRef.get();

      if (!appointmentSnapshot.exists) {
        throw Exception(
          'Appointment not found.',
        );
      }

      final appointmentData =
          appointmentSnapshot.data();

      if (appointmentData == null) {
        throw Exception(
          'Appointment data is empty.',
        );
      }

      // --------------------------------------------------------
      // 2. Get departmentId from existing appointment
      // --------------------------------------------------------

      final departmentId =
          (appointmentData['departmentId'] ?? '')
              .toString();

      if (departmentId.isEmpty) {
        throw Exception(
          'Department ID is missing from the appointment.',
        );
      }

      // --------------------------------------------------------
      // 3. Find selected slot
      // --------------------------------------------------------

      final selectedSlot = timeSlots.firstWhere(
        (slot) =>
            slot['displayTime'] == selectedTime,
        orElse: () => timeSlots.first,
      );

      final newDate = _formatDate(selectedDate);

      final newTime =
          selectedSlot['displayTime']!;

      // --------------------------------------------------------
      // 4. Generate NEW token for the new appointment date
      // --------------------------------------------------------

      final newToken =
          await _generateNextTokenCode(
        departmentId: departmentId,
        appointmentDate: newDate,
      );

      // --------------------------------------------------------
      // 5. Update SAME appointment document in Firestore
      // --------------------------------------------------------

      await appointmentRef.update({
        'appointmentDate': newDate,
        'startTime': selectedSlot['startTime'],
        'endTime': selectedSlot['endTime'],
        'timeSlot': newTime,
        'slotId': selectedSlot['id'],

        // IMPORTANT:
        // Replace old token with the new token.
        'tokenCode': newToken,

        'status': 'rescheduled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      // --------------------------------------------------------
      // 6. Go directly to Digital Token screen
      //
      // SAME appointmentId is passed.
      // Digital Token screen can read the updated Firestore
      // document and show the new token/date/time/QR.
      // --------------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DigitalTokenDetailsScreen(
            appointmentId:
                widget.appointmentId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to reschedule appointment: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SLOT CARD
  // ============================================================

  Widget _buildSlotCard(
    Map<String, String> slot,
  ) {
    final displayTime =
        slot['displayTime']!;

    final isSelected =
        selectedTime == displayTime;

    return GestureDetector(
      onTap: isSaving
          ? null
          : () {
              setState(() {
                selectedTime = displayTime;
              });
            },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
                  .withOpacity(0.08)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.shade300,
            width:
                isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 16,
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.shade600,
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Text(
                displayTime,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),

            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 17,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detail(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value.isEmpty
                  ? 'Not available'
                  : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final morningSlots =
        timeSlots.sublist(0, 4);

    final afternoonSlots =
        timeSlots.sublist(4, 6);

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color:
                AppColors.textPrimary,
          ),
          onPressed: isSaving
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),

        title: const Text(
          'Reschedule Appointment',
          style: TextStyle(
            color:
                AppColors.textPrimary,
            fontWeight:
                FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // CURRENT APPOINTMENT
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Current Appointment',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _detail(
                    'Hospital',
                    widget.hospital,
                  ),

                  _detail(
                    'Clinic',
                    widget.clinic,
                  ),

                  _detail(
                    'Doctor',
                    widget.doctor,
                  ),

                  _detail(
                    'Date',
                    widget.date,
                  ),

                  _detail(
                    'Time',
                    widget.time,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ==================================================
            // NEW DATE
            // ==================================================

            const Text(
              'Choose New Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textPrimary,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            GestureDetector(
              onTap: isSaving
                  ? null
                  : _chooseDate,

              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        Colors.grey.shade200,
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(8),
                      decoration:
                          BoxDecoration(
                        color: AppColors
                            .primary
                            .withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),

                      child: const Icon(
                        Icons
                            .calendar_month_rounded,
                        size: 20,
                        color:
                            AppColors.primary,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Text(
                        _displayDate(
                          selectedDate,
                        ),
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons
                          .keyboard_arrow_down_rounded,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // TIME SLOTS
            // ==================================================

            const Text(
              'Available Time Slots',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textPrimary,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Select a suitable time for your appointment',
              style: TextStyle(
                fontSize: 12,
                color:
                    AppColors.textSecondary,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // MORNING
            // ==================================================

            Row(
              children: [
                Icon(
                  Icons.wb_sunny_rounded,
                  size: 18,
                  color:
                      Colors.orange.shade700,
                ),

                const SizedBox(
                  width: 8,
                ),

                const Text(
                  'Morning Session',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount:
                  morningSlots.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemBuilder:
                  (context, index) {
                return _buildSlotCard(
                  morningSlots[index],
                );
              },
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // AFTERNOON
            // ==================================================

            Row(
              children: [
                Icon(
                  Icons.wb_twilight_rounded,
                  size: 18,
                  color:
                      Colors.blueGrey.shade700,
                ),

                const SizedBox(
                  width: 8,
                ),

                const Text(
                  'Afternoon Session',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount:
                  afternoonSlots.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemBuilder:
                  (context, index) {
                return _buildSlotCard(
                  afternoonSlots[index],
                );
              },
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // CONFIRM RESCHEDULE
            // ==================================================

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

                onPressed: isSaving
                    ? null
                    : _confirmReschedule,

                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm Reschedule',
                        style: TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // KEEP CURRENT APPOINTMENT
            // ==================================================

            SizedBox(
              width: double.infinity,

              child: OutlinedButton(
                style:
                    OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  side:
                      const BorderSide(
                    color:
                        AppColors.primary,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),

                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                        );
                      },

                child: const Text(
                  'Keep Current Appointment',
                  style: TextStyle(
                    color:
                        AppColors.primary,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}