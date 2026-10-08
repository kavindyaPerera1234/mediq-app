import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../backend/backend.dart';

class AdminTimeSlotConfig {
  final String id;
  String slotRange;
  int capacity;
  int bookedCount;
  bool isClosed;
  String reason;

  AdminTimeSlotConfig({
    required this.id,
    required this.slotRange,
    required this.capacity,
    required this.bookedCount,
    this.isClosed = false,
    this.reason = '',
  });

  bool get isFull => bookedCount >= capacity;
}

class ManageAppointmentSlotsScreen extends StatefulWidget {
  const ManageAppointmentSlotsScreen({super.key});

  @override
  State<ManageAppointmentSlotsScreen> createState() => _ManageAppointmentSlotsScreenState();
}

class _ManageAppointmentSlotsScreenState extends State<ManageAppointmentSlotsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedClinic = 'General Medicine OPD (Room 01)';

  final List<String> _clinicOptions = [
    'General Medicine OPD (Room 01)',
    'ENT Clinic (Room 02)',
    'Orthopedics Clinic (Room 03)',
    'Pediatrics Clinic (Room 04)',
    'Cardiology Clinic (Room 05)',
  ];

  final List<AdminTimeSlotConfig> _slots = [
    AdminTimeSlotConfig(
      id: 'slot_1',
      slotRange: '08:00 AM - 09:00 AM',
      capacity: 25,
      bookedCount: 0,
      isClosed: false,
    ),
    AdminTimeSlotConfig(
      id: 'slot_2',
      slotRange: '09:00 AM - 10:00 AM',
      capacity: 25,
      bookedCount: 0,
      isClosed: false,
    ),
    AdminTimeSlotConfig(
      id: 'slot_3',
      slotRange: '10:00 AM - 11:00 AM',
      capacity: 25,
      bookedCount: 0,
      isClosed: false,
    ),
    AdminTimeSlotConfig(
      id: 'slot_4',
      slotRange: '11:00 AM - 12:00 PM',
      capacity: 25,
      bookedCount: 0,
      isClosed: false,
    ),
    AdminTimeSlotConfig(
      id: 'slot_5',
      slotRange: '12:00 PM - 01:00 PM',
      capacity: 25,
      bookedCount: 0,
      isClosed: false,
    ),
    AdminTimeSlotConfig(
      id: 'slot_6',
      slotRange: '01:00 PM - 02:00 PM',
      capacity: 25,
      bookedCount: 0,
      isClosed: false,
    ),
  ];

  void _editSlotCapacity(AdminTimeSlotConfig slot) {
    int tempCapacity = slot.capacity;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Adjust Capacity • ${slot.slotRange}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MoH Guideline: Max slot capacity is capped at 25 to prevent waiting hall overcrowding.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Max Patients:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: AppColors.primary),
                              onPressed: tempCapacity > slot.bookedCount && tempCapacity > 5
                                  ? () => setDialogState(() => tempCapacity -= 5)
                                  : null,
                            ),
                            Text(
                              '$tempCapacity',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              onPressed: tempCapacity < 50
                                  ? () => setDialogState(() => tempCapacity += 5)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      slot.capacity = tempCapacity;
                    });
                    _syncSlotToFirestore(slot);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Capacity updated to $tempCapacity for ${slot.slotRange}'),
                        backgroundColor: AppColors.statusGreen,
                      ),
                    );
                  },
                  child: const Text('Save Capacity'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleSlotClosure(AdminTimeSlotConfig slot) {
    setState(() {
      slot.isClosed = !slot.isClosed;
      if (slot.isClosed) {
        slot.reason = 'Doctor Leave / Emergency';
      } else {
        slot.reason = '';
      }
    });

    _syncSlotToFirestore(slot);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          slot.isClosed
              ? '${slot.slotRange} is now CLOSED for bookings.'
              : '${slot.slotRange} is now OPEN for bookings.',
        ),
        backgroundColor: slot.isClosed ? AppColors.error : AppColors.statusGreen,
      ),
    );
  }

  Future<void> _syncSlotToFirestore(AdminTimeSlotConfig slot) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await HospitalAdminService().updateSlotConfig(
        slotId: slot.id,
        slotRange: slot.slotRange,
        date: dateStr,
        clinic: _selectedClinic,
        capacity: slot.capacity,
        bookedCount: slot.bookedCount,
        isClosed: slot.isClosed,
        reason: slot.reason,
      );
    } catch (_) {}
  }

  void _closeAllSlotsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Close All Slots Today?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'This will mark all 6 time slots as CLOSED (e.g. unexpected doctor absence or public holiday). Patients will not be able to book into this date.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  for (var slot in _slots) {
                    slot.isClosed = true;
                    slot.reason = 'Doctor Unavailable';
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All slots closed for today.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
              child: const Text('Close All Slots'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Slot Capping & Capacity',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.block_rounded, color: Colors.amberAccent),
            tooltip: 'Emergency Close All Slots',
            onPressed: _closeAllSlotsDialog,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              // Date & Clinic Selection Header
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  children: [
                    // Date Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selected Clinic Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(formattedDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          ],
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month_outlined, size: 16),
                          label: const Text('Change Date', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E293B),
                            side: const BorderSide(color: Color(0xFF1E293B)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 60)),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Clinic Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedClinic,
                          isExpanded: true,
                          items: _clinicOptions.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedClinic = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Slots List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _slots.length,
                  itemBuilder: (context, index) {
                    final slot = _slots[index];
                    final fillRatio = (slot.bookedCount / slot.capacity).clamp(0.0, 1.0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: slot.isClosed ? const Color(0xFFF1F5F9) : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: slot.isClosed
                              ? AppColors.error.withValues(alpha: 0.3)
                              : slot.isFull
                                  ? AppColors.statusOrange.withValues(alpha: 0.4)
                                  : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                    color: slot.isClosed ? AppColors.textMuted : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    slot.slotRange,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: slot.isClosed ? AppColors.textMuted : AppColors.textDark,
                                      decoration: slot.isClosed ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: slot.isClosed
                                      ? AppColors.error.withValues(alpha: 0.12)
                                      : slot.isFull
                                          ? AppColors.errorLight
                                          : AppColors.successLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  slot.isClosed
                                      ? 'CLOSED'
                                      : slot.isFull
                                          ? 'FULL (25/25)'
                                          : 'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: slot.isClosed
                                        ? AppColors.error
                                        : slot.isFull
                                            ? AppColors.error
                                            : AppColors.statusGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Capacity bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: slot.isClosed ? 0 : fillRatio,
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                slot.isClosed
                                    ? AppColors.textMuted
                                    : slot.isFull
                                        ? AppColors.error
                                        : AppColors.statusGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${slot.bookedCount} / ${slot.capacity} Patients Booked',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              Row(
                                children: [
                                  // Edit capacity button
                                  TextButton.icon(
                                    icon: const Icon(Icons.tune_rounded, size: 14),
                                    label: const Text('Cap Limit', style: TextStyle(fontSize: 12)),
                                    onPressed: () => _editSlotCapacity(slot),
                                  ),
                                  const SizedBox(width: 4),

                                  // Close / Open toggle button
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: slot.isClosed ? AppColors.statusGreen : AppColors.error,
                                      side: BorderSide(
                                        color: slot.isClosed ? AppColors.statusGreen : AppColors.error,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    onPressed: () => _toggleSlotClosure(slot),
                                    child: Text(
                                      slot.isClosed ? 'Reopen' : 'Close Slot',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
