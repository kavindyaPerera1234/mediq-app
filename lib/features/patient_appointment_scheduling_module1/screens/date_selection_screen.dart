import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../../../core/constants/app_translations.dart';
import '../backend/backend.dart';
import 'time_slot_selection_screen.dart';

class DateSelectionScreen extends StatefulWidget {
  final GovernmentHospital hospital;
  final OpdClinic clinic;
  final bool isCaregiverBooking;
  final String patientName;
  final String patientNic;
  final String relationship;
  final String priority;

  const DateSelectionScreen({
    super.key,
    required this.hospital,
    required this.clinic,
    this.isCaregiverBooking = false,
    this.patientName = 'Patient',
    this.patientNic = 'N/A',
    this.relationship = 'Self',
    this.priority = 'normal',
  });

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  StreamSubscription<QuerySnapshot>? _appointmentsSub;
  int _bookedCount = 0;

  @override
  void initState() {
    super.initState();
    // Default to today or tomorrow
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
    _listenForDateBookings();
  }

  @override
  void dispose() {
    _appointmentsSub?.cancel();
    super.dispose();
  }

  void _listenForDateBookings() {
    _appointmentsSub?.cancel();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final altDate = '${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}';

    _appointmentsSub = FirebaseFirestore.instance
        .collection('appointments')
        .where('appointmentDate', whereIn: [dateStr, altDate])
        .snapshots()
        .listen((snapshot) {
      int count = 0;
      final currentHospId = widget.hospital.id.toLowerCase();
      final currentHospName = widget.hospital.name.toLowerCase();
      final currentDeptId = widget.clinic.id.toLowerCase();
      final currentDeptName = widget.clinic.name.toLowerCase();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'cancelled') continue;

        final appHospId = (data['hospitalId'] ?? '').toString().toLowerCase();
        final appHospName = (data['hospitalName'] ?? '').toString().toLowerCase();
        final appDeptId = (data['departmentId'] ?? data['clinicId'] ?? '').toString().toLowerCase();
        final appDeptName = (data['departmentName'] ?? data['clinicName'] ?? '').toString().toLowerCase();

        final bool hospMatch = appHospId.isEmpty ||
            appHospName.isEmpty ||
            appHospId == currentHospId ||
            currentHospId.contains(appHospId) ||
            appHospId.contains(currentHospId) ||
            appHospName == currentHospName ||
            currentHospName.contains(appHospName) ||
            appHospName.contains(currentHospName) ||
            (currentHospName.contains('national') && (appHospName.contains('national') || appHospId.contains('nhsl') || appHospId.contains('hosp-001') || appHospId.contains('hosp_02'))) ||
            (currentHospName.contains('colombo south') && (appHospName.contains('colombo south') || appHospId.contains('csth') || appHospName.contains('kalubowila')));

        final bool clinicMatch = appDeptId.isEmpty ||
            appDeptName.isEmpty ||
            appDeptId == currentDeptId ||
            currentDeptId.contains(appDeptId) ||
            appDeptId.contains(currentDeptId) ||
            appDeptName == currentDeptName ||
            currentDeptName.contains(appDeptName) ||
            appDeptName.contains(currentDeptName) ||
            (currentDeptName.contains('derma') && (appDeptName.contains('derma') || appDeptName.contains('skin') || appDeptId.contains('derma') || appDeptId.contains('dep-004'))) ||
            (currentDeptName.contains('skin') && (appDeptName.contains('skin') || appDeptName.contains('derma') || appDeptId.contains('derma'))) ||
            (currentDeptName.contains('general') && (appDeptName.contains('general') || appDeptId.contains('gen_med') || appDeptId.contains('dep-001'))) ||
            (currentDeptName.contains('ortho') && (appDeptName.contains('ortho') || appDeptId.contains('ortho') || appDeptId.contains('bone'))) ||
            (currentDeptName.contains('ent') && (appDeptName.contains('ent') || appDeptId.contains('ent') || appDeptId.contains('ear'))) ||
            (currentDeptName.contains('pedia') && (appDeptName.contains('pedia') || appDeptId.contains('pedia') || appDeptId.contains('child')));

        if (hospMatch && clinicMatch) {
          count++;
        }
      }

      if (mounted) {
        setState(() {
          _bookedCount = count;
        });
      }
    }, onError: (_) {});
  }

  void _proceedToTimeSlots() {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'TimeSlotSelection'),
        builder: (context) => TimeSlotSelectionScreen(
          hospital: widget.hospital,
          clinic: widget.clinic,
          selectedDate: _selectedDay,
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
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(_selectedDay);

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
              AppTranslations.tr('chooseDate'),
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
                  // Segmented 5-Step Stepper (Step 4 of 5)
                  _buildSegmentedStepper(),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Context Summary Card (Hospital & Clinic)
                          _buildBookingContextCard(),

                          const SizedBox(height: 16),

                          Text(
                            AppTranslations.tr('chooseDate'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.headingText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppTranslations.tr('chooseDateSubtitle'),
                            style: TextStyle(fontSize: 13, color: AppColors.bodyText, height: 1.3),
                          ),
                          const SizedBox(height: 16),

                          // Interactive Calendar Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.isDark ? Colors.black26 : AppColors.textDark.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                TableCalendar(
                                  firstDay: DateTime.now().subtract(const Duration(days: 1)),
                                  lastDay: DateTime.now().add(const Duration(days: 90)),
                                  focusedDay: _focusedDay,
                                  currentDay: DateTime.now(),
                                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                  // Prevent selecting Sundays or past days
                                  enabledDayPredicate: (day) {
                                    return day.weekday != DateTime.sunday &&
                                        day.isAfter(DateTime.now().subtract(const Duration(days: 1)));
                                  },
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedDay = selectedDay;
                                      _focusedDay = focusedDay;
                                    });
                                    _listenForDateBookings();
                                  },
                                  headerStyle: HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                    titleTextStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.headingText,
                                    ),
                                    leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.accentColor),
                                    rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.accentColor),
                                  ),
                                  calendarStyle: CalendarStyle(
                                    outsideDaysVisible: false,
                                    selectedDecoration: BoxDecoration(
                                      color: AppColors.accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                    selectedTextStyle: TextStyle(
                                      color: isDark ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    defaultTextStyle: TextStyle(
                                      color: AppColors.headingText,
                                      fontSize: 14,
                                    ),
                                    weekendTextStyle: const TextStyle(
                                      color: AppColors.statusOrange,
                                      fontSize: 14,
                                    ),
                                    disabledTextStyle: TextStyle(
                                      color: AppColors.bodyText.withValues(alpha: 0.5),
                                      fontSize: 14,
                                    ),
                                    todayDecoration: BoxDecoration(
                                      color: AppColors.chipBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.accentColor, width: 1.2),
                                    ),
                                    todayTextStyle: TextStyle(
                                      color: AppColors.accentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Divider(height: 24, color: AppColors.cardBorder),

                                // Calendar Legend
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildLegend(AppColors.accentColor, 'Selected'),
                                    const SizedBox(width: 14),
                                    _buildLegend(AppColors.headingText, 'Available'),
                                    const SizedBox(width: 14),
                                    _buildLegend(AppColors.bodyText, 'Closed / Sunday'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Selected Date Confirmation Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.chipBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.accentColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  AppTranslations.tr('selectedDateHeader'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.headingText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (_) {
                                    final isSunday = _selectedDay.weekday == DateTime.sunday;
                                    if (isSunday) {
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.cancel_outlined, size: 14, color: AppColors.statusRed),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Clinic Closed on Sundays • Select a Weekday',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.statusRed,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    final available = (150 - _bookedCount).clamp(0, 150);
                                    final isFull = available == 0;

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isFull ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                                          size: 14,
                                          color: isFull ? AppColors.statusOrange : AppColors.statusGreen,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            isFull
                                                ? 'All 150 OPD Slots Fully Booked for this date'
                                                : 'Sessions Open (8 AM - 2 PM) • $available/150 spots available',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isFull ? AppColors.statusOrange : AppColors.statusGreen,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Pinned Bottom Continue Button
                  _buildBottomActionBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Segmented 5-Step Stepper with interactive tap-back
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
                AppTranslations.tr('step4Title'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentColor,
                ),
              ),
              Text(
                AppTranslations.tr('nextSlot'),
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
                    return route.settings.name == 'HospitalSelection' || count++ == 2;
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
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 4,
                label: 'Date',
                isActive: true,
                isCompleted: false,
                onTap: null,
              ),
              const SizedBox(width: 6),
              _buildStepSegment(
                step: 5,
                label: 'Slot',
                isActive: false,
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
  Widget _buildBookingContextCard() {
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
                  '${widget.clinic.name} • ${widget.clinic.hours}',
                  style: TextStyle(fontSize: 12, color: AppColors.bodyText),
                ),
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

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: AppColors.bodyText),
        ),
      ],
    );
  }

  // Bottom Continue Action Button
  Widget _buildBottomActionBar() {
    final isSunday = _selectedDay.weekday == DateTime.sunday;
    final available = (150 - _bookedCount).clamp(0, 150);
    final isFull = available == 0;

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
            onPressed: isSunday
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('OPD Clinic is closed on Sundays. Please select a weekday (Monday - Saturday).'),
                        backgroundColor: AppColors.statusRed,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                : (isFull
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All slots are fully booked for this date. Please select another date.'),
                            backgroundColor: AppColors.statusOrange,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    : _proceedToTimeSlots),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSunday || isFull ? AppColors.cardBorder : AppColors.accentColor,
              foregroundColor: isSunday || isFull ? AppColors.bodyText : (AppColors.isDark ? Colors.black : Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppTranslations.tr('continueToSlots'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.isDark ? Colors.black : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.isDark ? Colors.black : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}