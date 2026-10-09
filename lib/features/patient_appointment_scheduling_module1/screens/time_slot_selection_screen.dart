import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/constants/app_translations.dart';
import '../backend/backend.dart';
import 'appointment_review_screen.dart';

class OpdTimeSlot {
  final String id;
  final String displayTime;
  final String session; // 'morning' or 'afternoon'
  final int bookedCount;
  final int maxCapacity;
  final bool isClosed;
  final bool isPast;

  const OpdTimeSlot({
    required this.id,
    required this.displayTime,
    required this.session,
    required this.bookedCount,
    this.maxCapacity = 25,
    this.isClosed = false,
    this.isPast = false,
  });

  bool get isFull => bookedCount >= maxCapacity;
  bool get isSelectable => !isFull && !isClosed && !isPast;
  int get remainingSlots => (maxCapacity - bookedCount).clamp(0, maxCapacity);
}

class TimeSlotSelectionScreen extends StatefulWidget {
  final GovernmentHospital hospital;
  final OpdClinic clinic;
  final DateTime selectedDate;
  final bool isCaregiverBooking;
  final String patientName;
  final String patientNic;
  final String relationship;
  final String priority;

  const TimeSlotSelectionScreen({
    super.key,
    required this.hospital,
    required this.clinic,
    required this.selectedDate,
    this.isCaregiverBooking = false,
    this.patientName = 'Patient',
    this.patientNic = '',
    this.relationship = 'Self',
    this.priority = 'normal',
  });

  @override
  State<TimeSlotSelectionScreen> createState() => _TimeSlotSelectionScreenState();
}

class _TimeSlotSelectionScreenState extends State<TimeSlotSelectionScreen> {
  String _selectedSlotId = 'slot_1';
  Map<String, int> _realBookedCounts = {};
  Map<String, int> _slotCapacities = {};
  Map<String, bool> _closedSlots = {};

  StreamSubscription<QuerySnapshot>? _appointmentsSub;
  StreamSubscription<QuerySnapshot>? _slotsSub;

  final List<OpdTimeSlot> _baseSlots = const [
    // Morning Slots
    OpdTimeSlot(
      id: 'slot_1',
      displayTime: '08:00 AM - 09:00 AM',
      session: 'morning',
      bookedCount: 0,
      maxCapacity: 25,
    ),
    OpdTimeSlot(
      id: 'slot_2',
      displayTime: '09:00 AM - 10:00 AM',
      session: 'morning',
      bookedCount: 0,
      maxCapacity: 25,
    ),
    OpdTimeSlot(
      id: 'slot_3',
      displayTime: '10:00 AM - 11:00 AM',
      session: 'morning',
      bookedCount: 0,
      maxCapacity: 25,
    ),
    OpdTimeSlot(
      id: 'slot_4',
      displayTime: '11:00 AM - 12:00 PM',
      session: 'morning',
      bookedCount: 0,
      maxCapacity: 25,
    ),

    // Afternoon Slots
    OpdTimeSlot(
      id: 'slot_5',
      displayTime: '12:00 PM - 01:00 PM',
      session: 'afternoon',
      bookedCount: 0,
      maxCapacity: 25,
    ),
    OpdTimeSlot(
      id: 'slot_6',
      displayTime: '01:00 PM - 02:00 PM',
      session: 'afternoon',
      bookedCount: 0,
      maxCapacity: 25,
    ),
  ];

  int? _getSlotIndex(String s) {
    final clean = s.toLowerCase().replaceAll(' ', '');
    if (clean.contains('slot_1') || clean.contains('slot1')) return 0;
    if (clean.contains('slot_2') || clean.contains('slot2')) return 1;
    if (clean.contains('slot_3') || clean.contains('slot3')) return 2;
    if (clean.contains('slot_4') || clean.contains('slot4')) return 3;
    if (clean.contains('slot_5') || clean.contains('slot5')) return 4;
    if (clean.contains('slot_6') || clean.contains('slot6')) return 5;

    // Slot 0: 08:00 - 09:00
    if ((clean.contains('08:') || clean.contains('8:') || clean.contains('8-') || clean.contains('08-')) &&
        (clean.contains('09:') || clean.contains('9:') || clean.contains('-9') || clean.contains('-09'))) {
      return 0;
    }
    // Slot 1: 09:00 - 10:00
    if ((clean.contains('09:') || clean.contains('9:') || clean.contains('9-') || clean.contains('09-')) &&
        clean.contains('10')) {
      return 1;
    }
    // Slot 2: 10:00 - 11:00
    if (clean.contains('10') && clean.contains('11')) return 2;
    // Slot 3: 11:00 - 12:00
    if (clean.contains('11') && clean.contains('12')) return 3;
    // Slot 4: 12:00 - 01:00 PM (or 13:00)
    if (clean.contains('12') && (clean.contains('1:') || clean.contains('01:') || clean.contains('-1') || clean.contains('-01') || clean.contains('13') || clean.contains('1pm') || clean.contains('01pm'))) {
      return 4;
    }
    // Slot 5: 01:00 - 02:00 PM (or 14:00)
    if ((clean.contains('1:') || clean.contains('01:') || clean.contains('1-') || clean.contains('01-') || clean.contains('13') || clean.contains('1pm') || clean.contains('01pm')) &&
        (clean.contains('2:') || clean.contains('02:') || clean.contains('-2') || clean.contains('-02') || clean.contains('14') || clean.contains('2pm') || clean.contains('02pm'))) {
      return 5;
    }

    return null;
  }

  List<OpdTimeSlot> get _slots {
    final now = DateTime.now();
    final isToday = widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;

    return _baseSlots.map((base) {
      final count = _realBookedCounts[base.id] ?? 0;
      final capacity = _slotCapacities[base.id] ?? _slotCapacities[base.displayTime] ?? base.maxCapacity;
      final isClosed = _closedSlots[base.id] == true || _closedSlots[base.displayTime] == true || base.isClosed;

      // Check if this time slot has already passed for today
      bool isPast = false;
      if (isToday) {
        int slotStartHour = 8;
        if (base.id == 'slot_1') {
          slotStartHour = 8;
        } else if (base.id == 'slot_2') {
          slotStartHour = 9;
        } else if (base.id == 'slot_3') {
          slotStartHour = 10;
        } else if (base.id == 'slot_4') {
          slotStartHour = 11;
        } else if (base.id == 'slot_5') {
          slotStartHour = 12;
        } else if (base.id == 'slot_6') {
          slotStartHour = 13;
        }

        if (now.hour >= slotStartHour) {
          isPast = true;
        }
      }

      return OpdTimeSlot(
        id: base.id,
        displayTime: base.displayTime,
        session: base.session,
        bookedCount: count,
        maxCapacity: capacity,
        isClosed: isClosed,
        isPast: isPast,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _recomputeSelection();
    _startRealtimeListeners();
  }

  @override
  void dispose() {
    _appointmentsSub?.cancel();
    _slotsSub?.cancel();
    super.dispose();
  }

  void _startRealtimeListeners() {
    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final altDate = '${widget.selectedDate.year}-${widget.selectedDate.month}-${widget.selectedDate.day}';

    _appointmentsSub?.cancel();
    _slotsSub?.cancel();

    // 1. Live stream of appointments for this date
    _appointmentsSub = FirebaseFirestore.instance
        .collection('appointments')
        .where('appointmentDate', whereIn: [formattedDate, altDate])
        .snapshots()
        .listen((querySnapshot) {
      final Map<String, int> counts = {};

      final currentHospId = widget.hospital.id.toLowerCase();
      final currentHospName = widget.hospital.name.toLowerCase();
      final currentDeptId = widget.clinic.id.toLowerCase();
      final currentDeptName = widget.clinic.name.toLowerCase();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'cancelled') continue;

        final appHospitalId = (data['hospitalId'] ?? '').toString().toLowerCase();
        final appHospitalName = (data['hospitalName'] ?? '').toString().toLowerCase();
        final appDeptId = (data['departmentId'] ?? data['clinicId'] ?? '').toString().toLowerCase();
        final appDeptName = (data['departmentName'] ?? data['clinicName'] ?? '').toString().toLowerCase();

        // 1. Hospital match:
        final bool isHospitalMatch = appHospitalId.isEmpty ||
            appHospitalName.isEmpty ||
            appHospitalId == currentHospId ||
            currentHospId.contains(appHospitalId) ||
            appHospitalId.contains(currentHospId) ||
            appHospitalName == currentHospName ||
            currentHospName.contains(appHospitalName) ||
            appHospitalName.contains(currentHospName) ||
            (currentHospName.contains('national') && (appHospitalName.contains('national') || appHospitalId.contains('nhsl') || appHospitalId.contains('hosp-001') || appHospitalId.contains('hosp_02'))) ||
            (currentHospName.contains('colombo south') && (appHospitalName.contains('colombo south') || appHospitalId.contains('csth') || appHospitalName.contains('kalubowila'))) ||
            (currentHospName.contains('teaching') && appHospitalName.contains('teaching')) ||
            (currentHospName.contains('ridgeway') && (appHospitalName.contains('ridgeway') || appHospitalId.contains('lrh'))) ||
            (currentHospName.contains('castle') && (appHospitalName.contains('castle') || appHospitalId.contains('cshw')));

        // 2. Clinic match:
        final bool isClinicMatch = appDeptId.isEmpty ||
            appDeptName.isEmpty ||
            appDeptId == currentDeptId ||
            appDeptId.contains(currentDeptId) ||
            currentDeptId.contains(appDeptId) ||
            appDeptName == currentDeptName ||
            currentDeptName.contains(appDeptName) ||
            appDeptName.contains(currentDeptName) ||
            (currentDeptName.contains('derma') && (appDeptName.contains('derma') || appDeptName.contains('skin') || appDeptId.contains('derma') || appDeptId.contains('dep-004'))) ||
            (currentDeptName.contains('skin') && (appDeptName.contains('skin') || appDeptName.contains('derma') || appDeptId.contains('derma'))) ||
            (currentDeptName.contains('general') && (appDeptName.contains('general') || appDeptId.contains('gen_med') || appDeptId.contains('dep-001'))) ||
            (currentDeptName.contains('ortho') && (appDeptName.contains('ortho') || appDeptId.contains('ortho') || appDeptId.contains('bone'))) ||
            (currentDeptName.contains('ent') && (appDeptName.contains('ent') || appDeptId.contains('ent') || appDeptId.contains('ear'))) ||
            (currentDeptName.contains('pedia') && (appDeptName.contains('pedia') || appDeptId.contains('pedia') || appDeptId.contains('child')));

        if (!isHospitalMatch || !isClinicMatch) continue;

        String slotTime = (data['timeSlot'] as String? ?? '').trim();
        if (slotTime.isEmpty) {
          final sTime = (data['startTime'] as String? ?? '').trim();
          final eTime = (data['endTime'] as String? ?? '').trim();
          if (sTime.isNotEmpty && eTime.isNotEmpty) {
            slotTime = '$sTime - $eTime';
          }
        }

        final slotIdx = _getSlotIndex(slotTime.isNotEmpty ? slotTime : (data['slotId'] ?? ''));
        if (slotIdx != null && slotIdx >= 0 && slotIdx < _baseSlots.length) {
          final baseSlotId = _baseSlots[slotIdx].id;
          counts[baseSlotId] = (counts[baseSlotId] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _realBookedCounts = counts;
          _recomputeSelection();
        });
      }
    }, onError: (e) {
      debugPrint('TimeSlotSelectionScreen: appointments stream notice: $e');
    });

    // 2. Live stream of admin slot capping and closures
    _slotsSub = FirebaseFirestore.instance
        .collection('appointment_slots')
        .where('date', isEqualTo: formattedDate)
        .snapshots()
        .listen((slotSnap) {
      final Map<String, int> customCapacities = {};
      final Map<String, bool> closedStatuses = {};

      for (final doc in slotSnap.docs) {
        final data = doc.data();
        final slotId = data['slotId'] as String? ?? '';
        final slotRange = data['slotRange'] as String? ?? '';
        final clinic = (data['clinic'] as String? ?? '').toLowerCase();

        final clinicNameLower = widget.clinic.name.toLowerCase();
        final clinicIdLower = widget.clinic.id.toLowerCase();
        final isMatching = clinic.isEmpty ||
            clinic.contains(clinicIdLower) ||
            clinicIdLower.contains(clinic) ||
            clinic.contains(clinicNameLower) ||
            clinicNameLower.contains(clinic) ||
            (clinicNameLower.contains('general') && clinic.contains('general'));

        if (isMatching) {
          if (data['capacity'] is num) {
            final cap = (data['capacity'] as num).toInt();
            if (slotId.isNotEmpty) customCapacities[slotId] = cap;
            if (slotRange.isNotEmpty) customCapacities[slotRange] = cap;
          }
          if (data['isClosed'] == true) {
            if (slotId.isNotEmpty) closedStatuses[slotId] = true;
            if (slotRange.isNotEmpty) closedStatuses[slotRange] = true;
          }
        }
      }

      if (mounted) {
        setState(() {
          _slotCapacities = customCapacities;
          _closedSlots = closedStatuses;
          _recomputeSelection();
        });
      }
    }, onError: (e) {
      debugPrint('TimeSlotSelectionScreen: slots stream notice: $e');
    });
  }

  bool _isSlotWithinOperatingHours(OpdTimeSlot slot, String operatingHours) {
    final clean = operatingHours.toLowerCase().replaceAll(' ', '');
    if (clean.isEmpty) return true;

    int clinicStartHour = 8;
    int clinicEndHour = 14; // Default to 2:00 PM (14:00)

    if (clean.contains('12:00pm') || clean.contains('12pm') || clean.contains('-12:00') || clean.contains('-12pm') || clean.contains('-12')) {
      clinicEndHour = 12;
    } else if (clean.contains('1:00pm') || clean.contains('01:00pm') || clean.contains('1pm') || clean.contains('01pm') || clean.contains('-1:00') || clean.contains('-01:00') || clean.contains('13:00')) {
      clinicEndHour = 13;
    } else if (clean.contains('2:00pm') || clean.contains('02:00pm') || clean.contains('2pm') || clean.contains('02pm') || clean.contains('-2:00') || clean.contains('14:00')) {
      clinicEndHour = 14;
    } else if (clean.contains('4:00pm') || clean.contains('04:00pm') || clean.contains('4pm') || clean.contains('16:00')) {
      clinicEndHour = 16;
    }

    if (clean.startsWith('12:') || clean.startsWith('12pm') || clean.startsWith('1:') || clean.startsWith('01:')) {
      clinicStartHour = 12;
    }

    int slotStartHour = 8;
    int slotEndHour = 9;
    if (slot.id == 'slot_1') {
      slotStartHour = 8; slotEndHour = 9;
    } else if (slot.id == 'slot_2') {
      slotStartHour = 9; slotEndHour = 10;
    } else if (slot.id == 'slot_3') {
      slotStartHour = 10; slotEndHour = 11;
    } else if (slot.id == 'slot_4') {
      slotStartHour = 11; slotEndHour = 12;
    } else if (slot.id == 'slot_5') {
      slotStartHour = 12; slotEndHour = 13;
    } else if (slot.id == 'slot_6') {
      slotStartHour = 13; slotEndHour = 14;
    }

    return slotStartHour >= clinicStartHour && slotEndHour <= clinicEndHour;
  }

  List<OpdTimeSlot> get _visibleSlots {
    final list = _slots.where((s) => _isSlotWithinOperatingHours(s, widget.clinic.hours)).toList();
    return list.isNotEmpty ? list : _slots;
  }

  void _recomputeSelection() {
    final visible = _visibleSlots;
    if (visible.isEmpty) return;

    if (!visible.any((s) => s.id == _selectedSlotId && s.isSelectable)) {
      final firstAvailable = visible.firstWhere(
        (s) => s.isSelectable,
        orElse: () => visible.first,
      );
      _selectedSlotId = firstAvailable.id;
    }
  }

  OpdTimeSlot get _currentSelectedSlot {
    final visible = _visibleSlots;
    if (visible.isEmpty) return _slots.first;
    return visible.firstWhere(
      (s) => s.id == _selectedSlotId,
      orElse: () => visible.first,
    );
  }

  void _proceedToReview() {
    if (!_currentSelectedSlot.isSelectable) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'AppointmentReview'),
        builder: (context) => AppointmentReviewScreen(
          hospital: widget.hospital,
          clinic: widget.clinic,
          selectedDate: widget.selectedDate,
          selectedTimeSlot: _currentSelectedSlot.displayTime,
          isCaregiverBooking: widget.isCaregiverBooking,
          patientName: widget.patientName,
          patientNic: widget.patientNic,
          relationship: widget.relationship,
          priority: widget.priority,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(widget.selectedDate);

    final morningSlots = _visibleSlots.where((s) => s.session == 'morning').toList();
    final afternoonSlots = _visibleSlots.where((s) => s.session == 'afternoon').toList();

    return AnimatedBuilder(
      animation: Listenable.merge([
        AppAccessibility.isHighContrastMode,
        AppAccessibility.currentLanguage,
      ]),
      builder: (context, _) {
        final isDark = AppAccessibility.isHighContrastMode.value;
        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: Text(
              AppTranslations.tr('step5Title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: AppColors.appBarBg,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: isDark ? 1 : 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  // Segmented 5-Step Stepper (Step 5 of 5)
                  _buildSegmentedStepper(),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 100.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Context Summary Card
                          _buildBookingContextCard(formattedDate),
                          const SizedBox(height: 16),

                          // HCI Capping Info Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.chipBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.accentColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppTranslations.tr('slotCappingNotice'),
                                    style: TextStyle(fontSize: 12, color: AppColors.accentColor, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 1. Morning Session Header & Grid
                          if (morningSlots.isNotEmpty) ...[
                            _buildSessionHeader(
                              icon: Icons.wb_sunny_rounded,
                              title: AppTranslations.tr('morningSession'),
                              subtitle: '08:00 AM - 12:00 PM',
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(height: 10),
                            _buildSlotGrid(morningSlots),
                            const SizedBox(height: 24),
                          ],

                          // 2. Afternoon Session Header & Grid
                          if (afternoonSlots.isNotEmpty) ...[
                            _buildSessionHeader(
                              icon: Icons.wb_twilight_rounded,
                              title: AppTranslations.tr('afternoonSession'),
                              subtitle: '12:00 PM - 02:00 PM',
                              color: Colors.blueGrey.shade700,
                            ),
                            const SizedBox(height: 10),
                            _buildSlotGrid(afternoonSlots),
                            const SizedBox(height: 20),
                          ],

                          // Clean Legend
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildLegendItem(AppColors.statusGreen, AppTranslations.tr('available')),
                                _buildLegendItem(AppColors.statusOrange, AppTranslations.tr('fillingFast')),
                                _buildLegendItem(AppColors.bodyText, AppTranslations.tr('fullLocked')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pinned Bottom Button
                  _buildBottomActionBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headingText),
        ),
        const SizedBox(width: 8),
        Text(
          '($subtitle)',
          style: TextStyle(fontSize: 12, color: AppColors.bodyText),
        ),
      ],
    );
  }

  // 2-Column Responsive Grid for Time Slots
  Widget _buildSlotGrid(List<OpdTimeSlot> slots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.95,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        return _buildModernSlotCard(slots[index]);
      },
    );
  }

  Widget _buildModernSlotCard(OpdTimeSlot slot) {
    final isSelected = _selectedSlotId == slot.id && slot.isSelectable;
    final isClosed = slot.isClosed;
    final isPast = slot.isPast;
    final isFull = slot.isFull;
    final isAlmostFull = !isFull && !isClosed && !isPast && slot.remainingSlots <= 5;
    final isDisabled = isClosed || isFull || isPast;

    return InkWell(
      onTap: slot.isSelectable
          ? () {
              setState(() {
                _selectedSlotId = slot.id;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDisabled
              ? (AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
              : isSelected
                  ? AppColors.chipBg
                  : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isClosed
                ? AppColors.error.withValues(alpha: 0.35)
                : isFull
                    ? AppColors.cardBorder
                    : isSelected
                        ? AppColors.accentColor
                        : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.accentColor.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Row with Clock Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isDisabled
                            ? AppColors.bodyText
                            : isSelected
                                ? AppColors.accentColor
                                : AppColors.bodyText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            slot.displayTime,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              decoration: null,
                              color: isDisabled
                                  ? AppColors.bodyText.withValues(alpha: 0.7)
                                  : isSelected
                                      ? AppColors.accentColor
                                      : AppColors.headingText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 16, color: AppColors.accentColor)
                else if (isPast)
                  Icon(Icons.schedule_rounded, size: 14, color: AppColors.bodyText.withValues(alpha: 0.6))
                else if (isClosed)
                  const Icon(Icons.block_rounded, size: 14, color: AppColors.error)
                else if (isFull)
                  Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.bodyText),
              ],
            ),
            const SizedBox(height: 6),

            // Availability Badge
            if (isPast)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ENDED (Time Passed)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.bodyText.withValues(alpha: 0.8),
                  ),
                ),
              )
            else if (isClosed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CLOSED (Doctor Leave)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              )
            else if (isFull)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Full (${slot.maxCapacity}/${slot.maxCapacity})',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentColor.withValues(alpha: 0.2)
                      : isAlmostFull
                          ? AppColors.statusOrange.withValues(alpha: 0.15)
                          : AppColors.statusGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isSelected
                      ? 'Selected (${slot.remainingSlots}/${slot.maxCapacity} left)'
                      : isAlmostFull
                          ? 'Only ${slot.remainingSlots}/${slot.maxCapacity} left'
                          : '${slot.remainingSlots}/${slot.maxCapacity} spots left',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.accentColor
                        : isAlmostFull
                            ? AppColors.statusOrange
                            : AppColors.statusGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Segmented 5-Step Stepper (Steps 1, 2, 3, 4 Completed Green, Step 5 Active Blue)
  Widget _buildSegmentedStepper() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.tr('step5Title'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentColor,
                ),
              ),
              Text(
                AppTranslations.tr('nextReview'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5 Segments with interactive navigation
          Row(
            children: [
              _buildStepSegment(
                step: 1,
                label: 'Patient',
                isActive: false,
                isCompleted: true,
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.settings.name == 'CaregiverSetup' || route.isFirst);
                },
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 2,
                label: 'Hospital',
                isActive: false,
                isCompleted: true,
                onTap: () {
                  int count = 0;
                  Navigator.of(context).popUntil((route) {
                    return route.settings.name == 'HospitalSelection' || count++ == 3;
                  });
                },
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 3,
                label: 'Clinic',
                isActive: false,
                isCompleted: true,
                onTap: () {
                  int count = 0;
                  Navigator.of(context).popUntil((route) {
                    return route.settings.name == 'ClinicSelection' || count++ == 2;
                  });
                },
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 4,
                label: 'Date',
                isActive: false,
                isCompleted: true,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 5,
                label: 'Slot',
                isActive: true,
                isCompleted: false,
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepSegment({
    required int step,
    required String label,
    required bool isActive,
    required bool isCompleted,
    VoidCallback? onTap,
  }) {
    final color = isActive
        ? AppColors.accentColor
        : isCompleted
            ? AppColors.statusGreen
            : AppColors.cardBorder;

    return Expanded(
      child: Tooltip(
        message: 'Step $step: $label${isCompleted ? ' (Tap to edit)' : ''}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$step. $label',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? AppColors.accentColor : (isCompleted ? AppColors.headingText : AppColors.bodyText),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Booking Context Card
  Widget _buildBookingContextCard(String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital_rounded, size: 16, color: AppColors.accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.hospital.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.statusOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.clinic.name} (${widget.clinic.roomNumber})',
                  style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.statusGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Patient: ${widget.patientName} (${widget.relationship})',
                  style: TextStyle(fontSize: 12, color: AppColors.bodyText, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: AppColors.bodyText),
        ),
      ],
    );
  }

  // Bottom Action Button with Arrow Icon
  Widget _buildBottomActionBar() {
    final canProceed = _currentSelectedSlot.isSelectable;
    final allSlotsEndedOrFull = _slots.every((s) => !s.isSelectable);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: canProceed ? _proceedToReview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed ? AppColors.accentColor : AppColors.cardBorder,
              foregroundColor: AppColors.isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  canProceed
                      ? AppTranslations.tr('reviewAppointment')
                      : (_currentSelectedSlot.isPast
                          ? (allSlotsEndedOrFull ? "OPD Sessions Ended • Change Date" : 'Selected Slot Ended')
                          : (_currentSelectedSlot.isClosed
                              ? 'Selected Slot Closed'
                              : 'Selected Slot Full')),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: canProceed
                        ? (AppColors.isDark ? Colors.black : Colors.white)
                        : AppColors.bodyText,
                  ),
                ),
                if (canProceed) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.isDark ? Colors.black : Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}