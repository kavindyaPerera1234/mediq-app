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

  const OpdTimeSlot({
    required this.id,
    required this.displayTime,
    required this.session,
    required this.bookedCount,
    this.maxCapacity = 25,
    this.isClosed = false,
  });

  bool get isFull => bookedCount >= maxCapacity;
  bool get isSelectable => !isFull && !isClosed;
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

  final List<OpdTimeSlot> _baseSlots = const [
    // Morning Slots
    OpdTimeSlot(
      id: 'slot_1',
      displayTime: '08:00 - 09:00 AM',
      session: 'morning',
      bookedCount: 0,
      maxCapacity: 25,
    ),
    OpdTimeSlot(
      id: 'slot_2',
      displayTime: '09:00 - 10:00 AM',
      session: 'morning',
      bookedCount: 0,
      maxCapacity: 25,
    ),
    OpdTimeSlot(
      id: 'slot_3',
      displayTime: '10:00 - 11:00 AM',
      session: 'morning',
      bookedCount: 0,
      maxCapacity: 25,
    ),
    OpdTimeSlot(
      id: 'slot_4',
      displayTime: '11:00 - 12:00 PM',
      session: 'morning',
      bookedCount: 0,
      maxCapacity: 25,
    ),

    // Afternoon Slots
    OpdTimeSlot(
      id: 'slot_5',
      displayTime: '12:00 - 01:00 PM',
      session: 'afternoon',
      bookedCount: 0,
      maxCapacity: 25,
    ),
    OpdTimeSlot(
      id: 'slot_6',
      displayTime: '01:00 - 02:00 PM',
      session: 'afternoon',
      bookedCount: 0,
      maxCapacity: 25,
    ),
  ];

  List<OpdTimeSlot> get _slots {
    return _baseSlots.map((base) {
      final count = _realBookedCounts[base.displayTime] ?? 0;
      return OpdTimeSlot(
        id: base.id,
        displayTime: base.displayTime,
        session: base.session,
        bookedCount: count,
        maxCapacity: base.maxCapacity,
        isClosed: base.isClosed,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchRealSlotBookings();
  }

  Future<void> _fetchRealSlotBookings() async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('departmentId', isEqualTo: widget.clinic.id)
          .where('appointmentDate', isEqualTo: formattedDate)
          .get()
          .timeout(const Duration(seconds: 4));

      final Map<String, int> counts = {};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'cancelled') continue;
        final slotTime = data['timeSlot'] as String? ?? '';
        if (slotTime.isNotEmpty) {
          counts[slotTime] = (counts[slotTime] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _realBookedCounts = counts;
        });
      }
    } catch (e) {
      debugPrint('TimeSlotSelectionScreen: fetchRealSlotBookings notice: $e');
    }
  }

  OpdTimeSlot get _currentSelectedSlot {
    return _slots.firstWhere(
      (s) => s.id == _selectedSlotId,
      orElse: () => _slots.first,
    );
  }

  void _proceedToReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
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

    final morningSlots = _slots.where((s) => s.session == 'morning').toList();
    final afternoonSlots = _slots.where((s) => s.session == 'afternoon').toList();

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

                          // 1. Morning Session Header
                          _buildSessionHeader(
                            icon: Icons.wb_sunny_rounded,
                            title: AppTranslations.tr('morningSession'),
                            subtitle: '08:00 AM - 12:00 PM',
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(height: 10),

                          // Morning Slots Grid (2 Columns)
                          _buildSlotGrid(morningSlots),

                          const SizedBox(height: 24),

                          // 2. Afternoon Session Header
                          _buildSessionHeader(
                            icon: Icons.wb_twilight_rounded,
                            title: AppTranslations.tr('afternoonSession'),
                            subtitle: '12:00 PM - 02:00 PM',
                            color: Colors.blueGrey.shade700,
                          ),
                          const SizedBox(height: 10),

                          // Afternoon Slots Grid (2 Columns)
                          _buildSlotGrid(afternoonSlots),

                          const SizedBox(height: 20),

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
        childAspectRatio: 2.1,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        return _buildModernSlotCard(slots[index]);
      },
    );
  }

  Widget _buildModernSlotCard(OpdTimeSlot slot) {
    final isSelected = _selectedSlotId == slot.id && slot.isSelectable;
    final isFull = slot.isFull;
    final isAlmostFull = !isFull && slot.remainingSlots <= 5;

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFull
              ? (AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
              : isSelected
                  ? AppColors.chipBg
                  : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFull
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
                        size: 14,
                        color: isFull
                            ? AppColors.bodyText
                            : isSelected
                                ? AppColors.accentColor
                                : AppColors.bodyText,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          slot.displayTime,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isFull
                                ? AppColors.bodyText
                                : isSelected
                                    ? AppColors.accentColor
                                    : AppColors.headingText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 16, color: AppColors.accentColor)
                else if (isFull)
                  Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.bodyText),
              ],
            ),
            const SizedBox(height: 6),

            // Availability Badge
            if (isFull)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Full (25/25)',
                  style: TextStyle(
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
                      ? 'Selected Slot'
                      : isAlmostFull
                          ? 'Only ${slot.remainingSlots} left'
                          : '${slot.remainingSlots} spots left',
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

          // 5 Segments
          Row(
            children: [
              _buildStepSegment(isActive: false, isCompleted: true),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: false, isCompleted: true),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: false, isCompleted: true),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: false, isCompleted: true),
              const SizedBox(width: 6),
              _buildStepSegment(isActive: true, isCompleted: false),
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
            onPressed: _proceedToReview,
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
                  AppTranslations.tr('reviewAppointment'),
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