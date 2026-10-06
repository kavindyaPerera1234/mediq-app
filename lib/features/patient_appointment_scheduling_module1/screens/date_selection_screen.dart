import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_accessibility.dart';
import '../backend/backend.dart';
import 'time_slot_selection_screen.dart';
import '../../auth_live_queue_module3/services/auth_service.dart';

class DateSelectionScreen extends StatefulWidget {
  final GovernmentHospital hospital;
  final OpdClinic clinic;
  final bool isCaregiverBooking;
  final String? patientName;
  final String? patientNic;
  final String relationship;
  final String priority;

  const DateSelectionScreen({
    super.key,
    required this.hospital,
    required this.clinic,
    this.isCaregiverBooking = false,
    this.patientName,
    this.patientNic,
    this.relationship = 'Self',
    this.priority = 'normal',
  });

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  String get effectivePatientName {
    if (widget.patientName != null && widget.patientName!.isNotEmpty && widget.patientName != 'Sandeepani Perera') {
      return widget.patientName!;
    }
    final user = AuthService().currentUser;
    return (user?.fullName.isNotEmpty == true) ? user!.fullName : 'Patient';
  }

  String get effectivePatientNic {
    if (widget.patientNic != null && widget.patientNic!.isNotEmpty && widget.patientNic != '200164801234') {
      return widget.patientNic!;
    }
    final user = AuthService().currentUser;
    return (user?.nic?.isNotEmpty == true)
        ? user!.nic!
        : (user?.phoneNumber.isNotEmpty == true ? user!.phoneNumber : (user?.userId ?? ''));
  }

  @override
  void initState() {
    super.initState();
    // Default to today or tomorrow
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
  }

  void _proceedToTimeSlots() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeSlotSelectionScreen(
          hospital: widget.hospital,
          clinic: widget.clinic,
          selectedDate: _selectedDay,
          isCaregiverBooking: widget.isCaregiverBooking,
          patientName: effectivePatientName,
          patientNic: effectivePatientNic,
          relationship: widget.relationship,
          priority: widget.priority,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(_selectedDay);

    return ValueListenableBuilder<bool>(
      valueListenable: AppAccessibility.isHighContrastMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppColors.pageBg,
          appBar: AppBar(
            title: const Text(
              'Select Appointment Date',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                            'Choose Clinic Date',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.headingText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select an available date on the OPD calendar for consultation.',
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
                                  'SELECTED APPOINTMENT DATE',
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.check_circle_rounded, size: 14, color: AppColors.statusGreen),
                                    SizedBox(width: 4),
                                    Text(
                                      'OPD Morning Session Available (8:00 AM - 12:00 PM)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.statusGreen,
                                      ),
                                    ),
                                  ],
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

  // Segmented 5-Step Stepper (Steps 1, 2, 3 Green, Step 4 Blue Active, Step 5 Grey)
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
                'Step 4 of 5: Date Selection',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentColor,
                ),
              ),
              Text(
                'Next: Time Slot',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5 Segments
          Row(
            children: [
              _buildStepSegment(isActive: false, isCompleted: true),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: false, isCompleted: true),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: false, isCompleted: true),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: true, isCompleted: false),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: false, isCompleted: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepSegment({required bool isActive, required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentColor
              : isCompleted
                  ? AppColors.statusGreen
                  : AppColors.cardBorder,
          borderRadius: BorderRadius.circular(3),
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
            onPressed: _proceedToTimeSlots,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
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
                  'Continue to Time Slots',
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