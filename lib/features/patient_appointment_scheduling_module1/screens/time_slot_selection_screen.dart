import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/hospital_model.dart';
import 'appointment_review_screen.dart';

class TimeSlot {
  final String time;
  final String slotRange;
  final bool isFull;

  TimeSlot({
    required this.time,
    required this.slotRange,
    this.isFull = false,
  });
}

class TimeSlotSelectionScreen extends StatefulWidget {
  final GovernmentHospital hospital;
  final OpdClinic clinic;
  final DateTime selectedDate;

  const TimeSlotSelectionScreen({
    super.key,
    required this.hospital,
    required this.clinic,
    required this.selectedDate,
  });

  @override
  State<TimeSlotSelectionScreen> createState() => _TimeSlotSelectionScreenState();
}

class _TimeSlotSelectionScreenState extends State<TimeSlotSelectionScreen> {
  String _selectedSlot = '8:30 AM';

  final List<TimeSlot> _morningSlots = [
    TimeSlot(time: '8:00 AM', slotRange: '8:00 AM - 8:30 AM'),
    TimeSlot(time: '8:30 AM', slotRange: '8:30 AM - 9:00 AM'),
    TimeSlot(time: '9:00 AM', slotRange: '9:00 AM - 9:30 AM'),
    TimeSlot(time: '9:30 AM', slotRange: '9:30 AM - 10:00 AM', isFull: true),
    TimeSlot(time: '10:00 AM', slotRange: '10:00 AM - 10:30 AM'),
    TimeSlot(time: '10:30 AM', slotRange: '10:30 AM - 11:00 AM'),
  ];

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMMM d').format(widget.selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Title & Clinic
              Text(
                'Choose Time',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Wed, Oct 14 • ${widget.clinic.name}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Selected Date Summary Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Date: $formattedDate',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Section Label
              Text(
                'Select an available morning time slot :',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              // 4. Time Slots Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: _morningSlots.length,
                  itemBuilder: (context, index) {
                    final slot = _morningSlots[index];
                    final isSelected = _selectedSlot == slot.time;
                    return _buildSlotCard(slot, isSelected);
                  },
                ),
              ),

              // 5. Review Appointment Button -> Navigates to AppointmentReviewScreen!
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to Screen 06: AppointmentReviewScreen!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentReviewScreen(
                          hospital: widget.hospital,
                          clinic: widget.clinic,
                          selectedDate: widget.selectedDate,
                          selectedTimeSlot: _selectedSlot,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Review Appointment',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(TimeSlot slot, bool isSelected) {
    if (slot.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slot.time,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Full',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSlot = slot.time;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withOpacity(0.35) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.borderActive : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slot.time,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isSelected ? 'Selected' : 'Available',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}