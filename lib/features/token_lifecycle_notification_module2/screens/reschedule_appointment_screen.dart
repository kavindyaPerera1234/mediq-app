import 'dart:async';

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
  // ============================================================
  // STATE
  // ============================================================

  late DateTime selectedDate;

  String selectedTime = '';

  bool isSaving = false;

  Map<String, int> bookedCounts = {};

  Map<String, int> capacities = {};

  Map<String, bool> closedSlots = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      appointmentsSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      slotsSubscription;

  // ============================================================
  // TIME SLOTS
  // SAME SLOTS AS THE ORIGINAL TIME SLOT SCREEN
  // ============================================================

  final List<Map<String, String>> timeSlots = [
    {
      'id': 'slot_1',
      'start': '08:00',
      'end': '09:00',
      'display': '08:00 AM - 09:00 AM',
      'session': 'morning',
    },
    {
      'id': 'slot_2',
      'start': '09:00',
      'end': '10:00',
      'display': '09:00 AM - 10:00 AM',
      'session': 'morning',
    },
    {
      'id': 'slot_3',
      'start': '10:00',
      'end': '11:00',
      'display': '10:00 AM - 11:00 AM',
      'session': 'morning',
    },
    {
      'id': 'slot_4',
      'start': '11:00',
      'end': '12:00',
      'display': '11:00 AM - 12:00 PM',
      'session': 'morning',
    },
    {
      'id': 'slot_5',
      'start': '12:00',
      'end': '13:00',
      'display': '12:00 PM - 01:00 PM',
      'session': 'afternoon',
    },
    {
      'id': 'slot_6',
      'start': '13:00',
      'end': '14:00',
      'display': '01:00 PM - 02:00 PM',
      'session': 'afternoon',
    },
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    selectedDate = _parseDate(widget.date);

    selectedTime = _findMatchingDisplayTime(widget.time);

    _loadAvailability();
  }

  @override
  void dispose() {
    appointmentsSubscription?.cancel();
    slotsSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime _parseDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed != null) {
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
      );
    }

    final match = RegExp(
      r'(\d{1,2})[\/\-. ](\d{1,2})[\/\-. ](\d{4})',
    ).firstMatch(value);

    if (match != null) {
      final first = int.tryParse(match.group(1)!);
      final second = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);

      if (first != null &&
          second != null &&
          year != null) {
        return DateTime(
          year,
          second,
          first,
        );
      }
    }

    return DateTime.now();
  }

  String _dateKey(DateTime date) {
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

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // TIME HELPERS
  // ============================================================

  String _findMatchingDisplayTime(String value) {
    final clean = value
        .toLowerCase()
        .replaceAll(' ', '');

    for (final slot in timeSlots) {
      final display = slot['display']!
          .toLowerCase()
          .replaceAll(' ', '');

      final id = slot['id']!
          .toLowerCase()
          .replaceAll(' ', '');

      final start = slot['start']!
          .replaceAll(':', '');

      final end = slot['end']!
          .replaceAll(':', '');

      if (clean == display ||
          clean == id ||
          (clean.contains(start) &&
              clean.contains(end))) {
        return slot['display']!;
      }
    }

    return '';
  }

  int? _slotIndex(String value) {
    final clean = value
        .toLowerCase()
        .replaceAll(' ', '');

    for (int i = 0; i < timeSlots.length; i++) {
      final slot = timeSlots[i];

      final display = slot['display']!
          .toLowerCase()
          .replaceAll(' ', '');

      final id = slot['id']!
          .toLowerCase()
          .replaceAll(' ', '');

      if (clean == display ||
          clean == id) {
        return i;
      }
    }

    if (clean.contains('08:') &&
        clean.contains('09:')) {
      return 0;
    }

    if (clean.contains('09:') &&
        clean.contains('10:')) {
      return 1;
    }

    if (clean.contains('10:') &&
        clean.contains('11:')) {
      return 2;
    }

    if (clean.contains('11:') &&
        clean.contains('12:')) {
      return 3;
    }

    if (clean.contains('12:') &&
        (clean.contains('13:') ||
            clean.contains('01:'))) {
      return 4;
    }

    if ((clean.contains('13:') ||
            clean.contains('01:')) &&
        (clean.contains('14:') ||
            clean.contains('02:'))) {
      return 5;
    }

    return null;
  }

  // ============================================================
  // CLINIC OPERATING HOURS
  //
  // General Medicine in your screenshot:
  // 08:00 AM - 12:00 PM
  //
  // If clinic name contains afternoon / 2 PM clinics,
  // 2 PM slots can also be shown.
  // ============================================================

  int _clinicEndHour() {
    final clinic =
        widget.clinic.toLowerCase();

    // General Medicine screenshot:
    // 08:00 AM - 12:00 PM
    if (clinic.contains('general medicine') ||
        clinic.contains('general opd') ||
        clinic.contains('general')) {
      return 12;
    }

    // Clinics that normally continue until 2 PM.
    return 14;
  }

  bool _withinClinicHours(
    Map<String, String> slot,
  ) {
    final startHour =
        int.parse(slot['start']!.split(':')[0]);

    final endHour =
        int.parse(slot['end']!.split(':')[0]);

    final clinicEnd =
        _clinicEndHour();

    return startHour >= 8 &&
        endHour <= clinicEnd;
  }

  List<Map<String, String>> get visibleSlots {
    return timeSlots
        .where(_withinClinicHours)
        .toList();
  }

  // ============================================================
  // REAL-TIME AVAILABILITY
  // ============================================================

  void _loadAvailability() {
    appointmentsSubscription?.cancel();
    slotsSubscription?.cancel();

    final date = _dateKey(selectedDate);

    // ----------------------------------------------------------
    // APPOINTMENTS
    // ----------------------------------------------------------

    appointmentsSubscription =
        FirebaseFirestore.instance
            .collection('appointments')
            .where(
              'appointmentDate',
              isEqualTo: date,
            )
            .snapshots()
            .listen(
      (snapshot) {
        final counts =
            <String, int>{};

        for (final doc in snapshot.docs) {
          final data = doc.data();

          final status =
              (data['status'] ?? '')
                  .toString()
                  .toLowerCase();

          // Cancelled appointments do not occupy slots.
          if (status == 'cancelled') {
            continue;
          }

          // Match the same hospital.
          final hospitalId =
              (data['hospitalId'] ?? '')
                  .toString()
                  .toLowerCase();

          final hospitalName =
              (data['hospitalName'] ?? '')
                  .toString()
                  .toLowerCase();

          final currentHospital =
              widget.hospital.toLowerCase();

          final hospitalMatches =
              hospitalId.isEmpty ||
                  hospitalName.isEmpty ||
                  hospitalId ==
                      currentHospital ||
                  hospitalName ==
                      currentHospital ||
                  hospitalId.contains(
                    currentHospital,
                  ) ||
                  hospitalName.contains(
                    currentHospital,
                  ) ||
                  currentHospital.contains(
                    hospitalId,
                  ) ||
                  currentHospital.contains(
                    hospitalName,
                  );

          if (!hospitalMatches) {
            continue;
          }

          // Match the same clinic.
          final departmentId =
              (data['departmentId'] ??
                      data['clinicId'] ??
                      '')
                  .toString()
                  .toLowerCase();

          final departmentName =
              (data['departmentName'] ??
                      data['clinicName'] ??
                      '')
                  .toString()
                  .toLowerCase();

          final currentClinic =
              widget.clinic.toLowerCase();

          final clinicMatches =
              departmentId.isEmpty ||
                  departmentName.isEmpty ||
                  departmentId ==
                      currentClinic ||
                  departmentName ==
                      currentClinic ||
                  departmentId.contains(
                    currentClinic,
                  ) ||
                  departmentName.contains(
                    currentClinic,
                  ) ||
                  currentClinic.contains(
                    departmentId,
                  ) ||
                  currentClinic.contains(
                    departmentName,
                  ) ||
                  (currentClinic.contains(
                        'general',
                      ) &&
                      (departmentName.contains(
                            'general',
                          ) ||
                          departmentId.contains(
                            'general',
                          ) ||
                          departmentId.contains(
                            'gen_med',
                          )));

          if (!clinicMatches) {
            continue;
          }

          // Get time slot.
          String slotValue =
              (data['timeSlot'] ?? '')
                  .toString()
                  .trim();

          if (slotValue.isEmpty) {
            final start =
                (data['startTime'] ?? '')
                    .toString()
                    .trim();

            final end =
                (data['endTime'] ?? '')
                    .toString()
                    .trim();

            if (start.isNotEmpty &&
                end.isNotEmpty) {
              slotValue =
                  '$start - $end';
            }
          }

          if (slotValue.isEmpty) {
            slotValue =
                (data['slotId'] ?? '')
                    .toString();
          }

          final index =
              _slotIndex(slotValue);

          if (index == null) {
            continue;
          }

          final slotId =
              timeSlots[index]['id']!;

          counts[slotId] =
              (counts[slotId] ?? 0) + 1;
        }

        if (!mounted) return;

        setState(() {
          bookedCounts = counts;
          _validateSelectedSlot();
        });
      },
      onError: (error) {
        debugPrint(
          'Appointment availability error: $error',
        );
      },
    );

    // ----------------------------------------------------------
    // APPOINTMENT SLOTS
    // ----------------------------------------------------------

    slotsSubscription =
        FirebaseFirestore.instance
            .collection('appointment_slots')
            .where(
              'date',
              isEqualTo: date,
            )
            .snapshots()
            .listen(
      (snapshot) {
        final newCapacities =
            <String, int>{};

        final newClosed =
            <String, bool>{};

        for (final doc in snapshot.docs) {
          final data = doc.data();

          final slotId =
              (data['slotId'] ?? '')
                  .toString();

          final slotRange =
              (data['slotRange'] ??
                      '')
                  .toString();

          final startTime =
              (data['startTime'] ?? '')
                  .toString();

          final endTime =
              (data['endTime'] ?? '')
                  .toString();

          final capacity =
              data['capacity'];

          if (capacity is num) {
            final value =
                capacity.toInt();

            if (slotId.isNotEmpty) {
              newCapacities[slotId] =
                  value;
            }

            if (slotRange.isNotEmpty) {
              newCapacities[slotRange] =
                  value;
            }

            if (startTime.isNotEmpty &&
                endTime.isNotEmpty) {
              newCapacities[
                    '$startTime - $endTime'] =
                  value;
            }
          }

          final status =
              (data['status'] ?? '')
                  .toString()
                  .toLowerCase();

          final isClosed =
              data['isClosed'] == true ||
              status == 'closed';

          if (isClosed) {
            if (slotId.isNotEmpty) {
              newClosed[slotId] =
                  true;
            }

            if (slotRange.isNotEmpty) {
              newClosed[slotRange] =
                  true;
            }
          }
        }

        if (!mounted) return;

        setState(() {
          capacities =
              newCapacities;

          closedSlots =
              newClosed;

          _validateSelectedSlot();
        });
      },
      onError: (error) {
        debugPrint(
          'Slot availability error: $error',
        );
      },
    );
  }

  // ============================================================
  // CAPACITY
  // ============================================================

  int _booked(
    Map<String, String> slot,
  ) {
    return bookedCounts[
            slot['id']] ??
        0;
  }

  int _capacity(
    Map<String, String> slot,
  ) {
    return capacities[
            slot['id']] ??
        capacities[
            slot['display']] ??
        25;
  }

  int _remaining(
    Map<String, String> slot,
  ) {
    final result =
        _capacity(slot) -
            _booked(slot);

    if (result < 0) {
      return 0;
    }

    return result;
  }

  bool _isFull(
    Map<String, String> slot,
  ) {
    return _remaining(slot) <= 0;
  }

  bool _isClosed(
    Map<String, String> slot,
  ) {
    return closedSlots[
              slot['id']] ==
          true ||
        closedSlots[
              slot['display']] ==
          true;
  }

  // ============================================================
  // PAST TIME
  // ============================================================

  bool _isPast(
    Map<String, String> slot,
  ) {
    final now = DateTime.now();

    final selectedDay =
        DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    // Previous dates.
    if (selectedDay.isBefore(today)) {
      return true;
    }

    // Future dates.
    if (selectedDay.isAfter(today)) {
      return false;
    }

    final endParts =
        slot['end']!.split(':');

    final endHour =
        int.parse(endParts[0]);

    final endMinute =
        int.parse(endParts[1]);

    final end =
        DateTime(
      today.year,
      today.month,
      today.day,
      endHour,
      endMinute,
    );

    return !now.isBefore(end);
  }

  bool _isAvailable(
    Map<String, String> slot,
  ) {
    return !_isFull(slot) &&
        !_isClosed(slot) &&
        !_isPast(slot);
  }

  // ============================================================
  // VALIDATE CURRENT SELECTION
  // ============================================================

  void _validateSelectedSlot() {
    if (selectedTime.isEmpty) {
      return;
    }

    final slot =
        timeSlots.where(
      (item) =>
          item['display'] ==
          selectedTime,
    );

    if (slot.isEmpty) {
      selectedTime = '';
      return;
    }

    if (!_isAvailable(slot.first)) {
      selectedTime = '';
    }
  }

  // ============================================================
  // DATE SELECTION
  // ============================================================

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    final initialDate =
        selectedDate.isBefore(today)
            ? today
            : selectedDate;

    final picked =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate:
          DateTime(2027, 12, 31),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate =
          DateTime(
        picked.year,
        picked.month,
        picked.day,
      );

      // New date = new time selection.
      selectedTime = '';
    });

    _loadAvailability();
  }

  // ============================================================
  // RESCHEDULE
  // ============================================================

  Future<void> _confirmReschedule() async {
    if (isSaving) {
      return;
    }

    if (widget.appointmentId.isEmpty) {
      _showMessage(
        'Appointment ID is missing.',
      );
      return;
    }

    if (selectedTime.isEmpty) {
      _showMessage(
        'Please select an available time slot.',
      );
      return;
    }

    final slot =
        timeSlots.firstWhere(
      (item) =>
          item['display'] ==
          selectedTime,
    );

    if (!_isAvailable(slot)) {
      _showMessage(
        'This time slot is no longer available.',
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final appointmentRef =
          FirebaseFirestore.instance
              .collection('appointments')
              .doc(
                widget.appointmentId,
              );

      final appointment =
          await appointmentRef.get();

      if (!appointment.exists) {
        throw Exception(
          'Appointment not found.',
        );
      }

      final data =
          appointment.data();

      if (data == null) {
        throw Exception(
          'Appointment data not found.',
        );
      }

      // --------------------------------------------------------
      // SAME APPOINTMENT IS UPDATED
      // NOT A NEW APPOINTMENT
      // --------------------------------------------------------

      await appointmentRef.update({
        'appointmentDate':
            _dateKey(selectedDate),

        'startTime':
            slot['start'],

        'endTime':
            slot['end'],

        'timeSlot':
            slot['display'],

        'slotId':
            slot['id'],

        'status':
            'rescheduled',

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      // --------------------------------------------------------
      // GO BACK TO DIGITAL TOKEN DETAILS
      // NO NEW CONFIRMATION SCREEN
      // --------------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DigitalTokenDetailsScreen(
            appointmentId:
                widget.appointmentId,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      debugPrint(
        'Reschedule error: $error',
      );

      _showMessage(
        'Unable to reschedule appointment.',
      );
    }
  }

  // ============================================================
  // SLOT CARD
  // ============================================================

  Widget _slotCard(
    Map<String, String> slot,
  ) {
    final selected =
        selectedTime ==
            slot['display'];

    final booked =
        _booked(slot);

    final capacity =
        _capacity(slot);

    final remaining =
        _remaining(slot);

    final full =
        _isFull(slot);

    final closed =
        _isClosed(slot);

    final past =
        _isPast(slot);

    final available =
        _isAvailable(slot);

    return GestureDetector(
      onTap: available
          ? () {
              setState(() {
                selectedTime =
                    slot['display']!;
              });
            }
          : null,

      child: Container(
        height: 78,

        padding:
            const EdgeInsets.all(10),

        decoration:
            BoxDecoration(
          color: selected
              ? AppColors.primary
                  .withOpacity(0.08)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.grey.shade300,

            width:
                selected ? 2 : 1,
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: selected
                      ? AppColors.primary
                      : Colors.grey.shade700,
                ),

                const SizedBox(
                  width: 5,
                ),

                Expanded(
                  child: FittedBox(
                    fit:
                        BoxFit.scaleDown,
                    alignment:
                        Alignment.centerLeft,

                    child: Text(
                      slot['display']!,
                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color: past ||
                                closed ||
                                full
                            ? Colors
                                .grey
                            : selected
                                ? AppColors
                                    .primary
                                : AppColors
                                    .textPrimary,
                      ),
                    ),
                  ),
                ),

                if (selected &&
                    available)
                  const Icon(
                    Icons.check_circle,
                    size: 15,
                    color:
                        AppColors.primary,
                  ),
              ],
            ),

            const SizedBox(
              height: 7,
            ),

            // -----------------------------------------------
            // AVAILABILITY TEXT
            // -----------------------------------------------

            if (past)
              _badge(
                'Time passed',
                Colors.grey.shade200,
                Colors.grey.shade700,
              )
            else if (closed)
              _badge(
                'Closed',
                Colors.red.shade50,
                Colors.red.shade700,
              )
            else if (full)
              _badge(
                'Full ($booked/$capacity)',
                Colors.red.shade50,
                Colors.red.shade700,
              )
            else if (selected)
              _badge(
                'Selected ($remaining/$capacity left)',
                AppColors.primary
                    .withOpacity(0.12),
                AppColors.primary,
              )
            else
              _badge(
                '$remaining/$capacity spots left',
                Colors.green.shade50,
                Colors.green.shade700,
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(
    String text,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),

      decoration:
          BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(4),
      ),

      child: Text(
        text,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,

        style: TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT APPOINTMENT CARD
  // ============================================================

  Widget _currentAppointmentCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _detailRow(
            'Hospital',
            widget.hospital,
          ),

          _detailRow(
            'Clinic',
            widget.clinic,
          ),

          _detailRow(
            'Doctor',
            widget.doctor,
          ),

          _detailRow(
            'Date',
            widget.date,
          ),

          _detailRow(
            'Time',
            _findMatchingDisplayTime(
                  widget.time,
                ).isEmpty
                ? widget.time
                : _findMatchingDisplayTime(
                    widget.time,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),

      child: Row(
        children: [
          SizedBox(
            width: 55,

            child: Text(
              label,

              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,

              style: const TextStyle(
                color:
                    AppColors.textPrimary,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final morning =
        visibleSlots
            .where(
              (slot) =>
                  slot['session'] ==
                  'morning',
            )
            .toList();

    final afternoon =
        visibleSlots
            .where(
              (slot) =>
                  slot['session'] ==
                  'afternoon',
            )
            .toList();

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            Colors.white,

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
                  Navigator.pop(
                    context,
                  );
                },
        ),

        title: const Text(
          'Reschedule Appointment',

          style: TextStyle(
            color:
                AppColors.textPrimary,
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            20,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // =================================================
              // CURRENT APPOINTMENT
              // =================================================

              _currentAppointmentCard(),

              const SizedBox(
                height: 18,
              ),

              // =================================================
              // CHOOSE DATE
              // =================================================

              const Text(
                'Choose New Date',

                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.textPrimary,
                ),
              ),

              const SizedBox(
                height: 9,
              ),

              GestureDetector(
                onTap: isSaving
                    ? null
                    : _selectDate,

                child: Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),

                    border: Border.all(
                      color:
                          Colors.grey.shade200,
                    ),
                  ),

                  child: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.all(
                          7,
                        ),

                        decoration:
                            BoxDecoration(
                          color: AppColors
                              .primary
                              .withOpacity(
                            0.08,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            7,
                          ),
                        ),

                        child: const Icon(
                          Icons
                              .calendar_month_rounded,
                          size: 19,
                          color:
                              AppColors.primary,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Text(
                          _displayDate(
                            selectedDate,
                          ),

                          style:
                              const TextStyle(
                            fontSize: 13,
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
                height: 20,
              ),

              // =================================================
              // TIME SLOTS TITLE
              // =================================================

              const Text(
                'Available Time Slots',

                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.textPrimary,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              const Text(
                'Select a suitable time for your appointment',

                style: TextStyle(
                  fontSize: 11,
                  color:
                      AppColors.textSecondary,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // MORNING SESSION
              // =================================================

              if (morning.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons
                          .wb_sunny_rounded,
                      size: 17,
                      color: Colors
                          .orange.shade700,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    const Text(
                      'Morning Session',

                      style:
                          TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Text(
                      '(08:00 AM - '
                      '${morning.last['end']}'
                      ' ${int.parse(morning.last['end']!.split(':')[0]) == 12 ? 'PM' : 'PM'})',

                      style:
                          const TextStyle(
                        fontSize: 10,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 9,
                ),

                GridView.builder(
                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  itemCount:
                      morning.length,

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                    childAspectRatio: 1.75,
                  ),

                  itemBuilder:
                      (context, index) {
                    return _slotCard(
                      morning[index],
                    );
                  },
                ),
              ],

              // =================================================
              // AFTERNOON SESSION
              // =================================================

              if (afternoon.isNotEmpty) ...[
                const SizedBox(
                  height: 20,
                ),

                Row(
                  children: [
                    Icon(
                      Icons
                          .wb_twilight_rounded,
                      size: 17,
                      color:
                          Colors.blueGrey,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    const Text(
                      'Afternoon Session',

                      style:
                          TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 9,
                ),

                GridView.builder(
                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  itemCount:
                      afternoon.length,

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                    childAspectRatio: 1.75,
                  ),

                  itemBuilder:
                      (context, index) {
                    return _slotCard(
                      afternoon[index],
                    );
                  },
                ),
              ],

              const SizedBox(
                height: 22,
              ),

              // =================================================
              // CONFIRM
              // =================================================

              SizedBox(
                width: double.infinity,

                child:
                    ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,

                    disabledBackgroundColor:
                        Colors.grey.shade300,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),
                  ),

                  onPressed:
                      isSaving ||
                              selectedTime.isEmpty
                          ? null
                          : _confirmReschedule,

                  child: isSaving
                      ? const SizedBox(
                          height: 19,
                          width: 19,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm Reschedule',

                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // =================================================
              // KEEP CURRENT
              // =================================================

              SizedBox(
                width: double.infinity,

                child:
                    OutlinedButton(
                  style:
                      OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 13,
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
                        11,
                      ),
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

                    style:
                        TextStyle(
                      color:
                          AppColors.primary,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}