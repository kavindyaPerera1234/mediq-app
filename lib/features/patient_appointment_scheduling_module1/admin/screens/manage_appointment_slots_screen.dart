import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  static const List<String> _defaultHospitalNames = [
    'Colombo North Teaching Hospital (Ragama)',
    'National Hospital of Sri Lanka',
    'Colombo South Teaching Hospital (Kalubowila)',
    'Lady Ridgeway Hospital for Children',
    'Teaching Hospital Kandy',
    'Teaching Hospital Anuradhapura',
    'Teaching Hospital Karapitiya (Galle)',
  ];

  List<String> _hospitalNames = List.from(_defaultHospitalNames);
  String _selectedHospital = 'Colombo North Teaching Hospital (Ragama)';

  String _selectedClinic = 'General Medicine OPD';
  List<String> _clinicOptions = [
    'General Medicine OPD',
    'Pediatric Clinic',
    'Cardiology Clinic',
    'Ophthalmology (Eye Clinic)',
    'ENT & Audiology Clinic',
    'Dental & Maxillofacial OPD',
    'Orthopedic Clinic',
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

  StreamSubscription<QuerySnapshot>? _deptSub;
  StreamSubscription<QuerySnapshot>? _hospSub;
  final Map<String, List<String>> _hospitalToClinics = {};

  @override
  void initState() {
    super.initState();
    _startFirestoreListeners();
    _loadSlotData();
  }

  @override
  void dispose() {
    _deptSub?.cancel();
    _hospSub?.cancel();
    super.dispose();
  }

  void _startFirestoreListeners() {
    // 1. Listen to hospitals collection
    _hospSub = FirebaseFirestore.instance
        .collection('hospitals')
        .snapshots()
        .listen((snap) {
      final List<String> names = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().trim();
        final isActive = data['isActive'] != false && data['isOpdAvailable'] != false;
        if (name.isNotEmpty && isActive && !names.contains(name)) {
          names.add(name);
        }
      }
      for (var def in _defaultHospitalNames) {
        if (!names.contains(def)) names.add(def);
      }

      if (mounted) {
        setState(() {
          _hospitalNames = names;
          if (!_hospitalNames.contains(_selectedHospital) && _hospitalNames.isNotEmpty) {
            _selectedHospital = _hospitalNames.first;
          }
        });
        _updateFilteredClinics();
      }
    });

    // 2. Listen to departments collection
    _deptSub = FirebaseFirestore.instance
        .collection('departments')
        .snapshots()
        .listen((snap) {
      final Map<String, List<String>> map = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['isActive'] == false) continue;
        final name = (data['name'] ?? '').toString().trim();
        final hosp = (data['hospitalName'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        if (hosp.isNotEmpty) {
          map.putIfAbsent(hosp, () => []);
          if (!map[hosp]!.contains(name)) {
            map[hosp]!.add(name);
          }
        }
      }

      if (mounted) {
        setState(() {
          _hospitalToClinics.clear();
          _hospitalToClinics.addAll(map);
        });
        _updateFilteredClinics();
      }
    });
  }

  void _updateFilteredClinics() {
    List<String> list = [];
    if (_hospitalToClinics.containsKey(_selectedHospital) && _hospitalToClinics[_selectedHospital]!.isNotEmpty) {
      list = List.from(_hospitalToClinics[_selectedHospital]!);
    } else {
      // Look for fuzzy matching
      for (final entry in _hospitalToClinics.entries) {
        final kA = entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final kB = _selectedHospital.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (kA.contains(kB) || kB.contains(kA)) {
          list = List.from(entry.value);
          break;
        }
      }
    }

    if (list.isEmpty) {
      list = [
        'General Medicine OPD',
        'Pediatric Clinic',
        'Cardiology Clinic',
        'Ophthalmology (Eye Clinic)',
        'ENT & Audiology Clinic',
        'Dental & Maxillofacial OPD',
        'Orthopedic Clinic',
      ];
    }

    setState(() {
      _clinicOptions = list;
      if (!_clinicOptions.contains(_selectedClinic)) {
        _selectedClinic = _clinicOptions.first;
      }
    });
    _loadSlotData();
  }

  bool _timesMatch(String a, String b) {
    String clean(String s) => s.replaceAll(' ', '').toUpperCase();
    return clean(a) == clean(b);
  }

  bool _clinicMatches(String a, String b) {
    final cleanA = a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanB = b.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (cleanA.isEmpty || cleanB.isEmpty) return true;
    return (cleanA.contains('general') && cleanB.contains('general')) ||
           (cleanA.contains('ent') && cleanB.contains('ent')) ||
           (cleanA.contains('ortho') && cleanB.contains('ortho')) ||
           (cleanA.contains('pedia') && cleanB.contains('pedia')) ||
           (cleanA.contains('cardio') && cleanB.contains('cardio')) ||
           (cleanA.contains('eye') && cleanB.contains('eye')) ||
           (cleanA.contains('dental') && cleanB.contains('dental')) ||
           cleanA == cleanB;
  }

  bool _hospitalMatches(String a, String b) {
    final cleanA = a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanB = b.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (cleanA.isEmpty || cleanB.isEmpty) return true;
    return cleanA.contains(cleanB) || cleanB.contains(cleanA);
  }

  Future<void> _loadSlotData() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // 1. Fetch appointments for this hospital, clinic, and date
      final appSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('appointmentDate', isEqualTo: dateStr)
          .get()
          .timeout(const Duration(seconds: 4));

      final Map<String, int> counts = {};
      for (final doc in appSnap.docs) {
        final data = doc.data();
        if (data['status'] == 'cancelled') continue;

        final hosp = (data['hospitalName'] ?? data['hospitalId'] ?? '').toString();
        if (hosp.isNotEmpty && !_hospitalMatches(hosp, _selectedHospital)) continue;

        final slotTime = (data['timeSlot'] as String? ?? '').trim();
        final clinic = (data['departmentName'] ?? data['clinicName'] ?? data['departmentId'] ?? '').toString();

        if (clinic.isNotEmpty && !_clinicMatches(clinic, _selectedClinic)) continue;

        if (slotTime.isNotEmpty) {
          counts[slotTime] = (counts[slotTime] ?? 0) + 1;
        }
      }

      // 2. Fetch slot configs from appointment_slots
      final slotSnap = await FirebaseFirestore.instance
          .collection('appointment_slots')
          .where('date', isEqualTo: dateStr)
          .get()
          .timeout(const Duration(seconds: 4));

      final Map<String, Map<String, dynamic>> configs = {};
      for (final doc in slotSnap.docs) {
        final data = doc.data();
        final slotId = data['slotId'] as String? ?? '';
        final clinic = (data['clinic'] as String? ?? '').toLowerCase();
        if (_clinicMatches(clinic, _selectedClinic)) {
          if (slotId.isNotEmpty) {
            configs[slotId] = data;
          }
        }
      }

      if (mounted) {
        setState(() {
          for (final slot in _slots) {
            int count = counts[slot.slotRange] ?? 0;
            if (count == 0) {
              for (final entry in counts.entries) {
                if (_timesMatch(entry.key, slot.slotRange)) {
                  count += entry.value;
                }
              }
            }
            slot.bookedCount = count;

            if (configs.containsKey(slot.id)) {
              final cfg = configs[slot.id]!;
              if (cfg['capacity'] is num) {
                slot.capacity = (cfg['capacity'] as num).toInt();
              }
              if (cfg['isClosed'] is bool) {
                slot.isClosed = cfg['isClosed'] as bool;
              }
              if (cfg['closureReason'] is String) {
                slot.reason = cfg['closureReason'] as String;
              }
            } else {
              slot.capacity = 25;
              slot.isClosed = false;
              slot.reason = '';
            }
          }
        });
      }
    } catch (e) {
      debugPrint('ManageAppointmentSlotsScreen: _loadSlotData notice: $e');
    }
  }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hospital: $_selectedHospital\nClinic: $_selectedClinic',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'MoH Guideline: Max slot capacity is capped at 25 to prevent waiting hall overcrowding.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
              Text('Emergency Close All Slots?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'This will mark all 6 time slots as CLOSED for "$_selectedClinic" at "$_selectedHospital" on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}.\n\nPatients will not be able to book appointments for this date.',
            style: const TextStyle(fontSize: 13, height: 1.4),
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
                for (var slot in _slots) {
                  _syncSlotToFirestore(slot);
                }
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
    final totalBooked = _slots.fold<int>(0, (acc, s) => acc + s.bookedCount);
    final totalCapacity = _slots.fold<int>(0, (acc, s) => acc + (s.isClosed ? 0 : s.capacity));
    final closedCount = _slots.where((s) => s.isClosed).length;

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
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            children: [
              // Top Hospital, Clinic & Date Controls Header
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hospital Selector
                    const Text('Government Hospital:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _hospitalNames.contains(_selectedHospital) ? _selectedHospital : (_hospitalNames.isNotEmpty ? _hospitalNames.first : null),
                          isExpanded: true,
                          icon: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 20),
                          items: _hospitalNames.map((name) {
                            return DropdownMenuItem(
                              value: name,
                              child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedHospital = val;
                              });
                              _updateFilteredClinics();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Clinic and Date Row
                    Row(
                      children: [
                        // Clinic Dropdown
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('OPD Clinic:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _clinicOptions.contains(_selectedClinic) ? _selectedClinic : (_clinicOptions.isNotEmpty ? _clinicOptions.first : null),
                                    isExpanded: true,
                                    icon: Icon(Icons.medical_services_rounded, color: AppColors.accentColor, size: 18),
                                    items: _clinicOptions.map((c) {
                                      return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedClinic = val;
                                        });
                                        _loadSlotData();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Date Button
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Clinic Date:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              InkWell(
                                onTap: () async {
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
                                    _loadSlotData();
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('MMM dd').format(_selectedDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. User-friendly summary bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Booked: $totalBooked / $totalCapacity Patients',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                          Text(
                            closedCount > 0 ? '$closedCount Closed' : 'All 6 Slots Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: closedCount > 0 ? AppColors.error : AppColors.statusGreen,
                            ),
                          ),
                        ],
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
                    final available = (slot.capacity - slot.bookedCount).clamp(0, slot.capacity);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: slot.isClosed ? const Color(0xFFF8FAFC) : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: slot.isClosed
                              ? AppColors.error.withValues(alpha: 0.3)
                              : slot.isFull
                                  ? AppColors.statusOrange.withValues(alpha: 0.4)
                                  : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                                    Icons.access_time_filled_rounded,
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
                                          ? AppColors.statusOrangeLight
                                          : AppColors.statusGreenLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  slot.isClosed
                                      ? 'CLOSED (Booking Paused)'
                                      : slot.isFull
                                          ? 'FULL (${slot.capacity}/${slot.capacity})'
                                          : 'ACTIVE ($available Available)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: slot.isClosed
                                        ? AppColors.error
                                        : slot.isFull
                                            ? AppColors.statusOrange
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
                              backgroundColor: AppColors.border.withValues(alpha: 0.5),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                slot.isClosed
                                    ? AppColors.textMuted
                                    : slot.isFull
                                        ? AppColors.statusOrange
                                        : AppColors.statusGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${slot.bookedCount} of ${slot.capacity} Patients Booked',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              Row(
                                children: [
                                  // Edit capacity button
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.tune_rounded, size: 13),
                                    label: const Text('Cap Limit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    onPressed: () => _editSlotCapacity(slot),
                                  ),
                                  const SizedBox(width: 6),

                                  // Close / Open toggle button
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: slot.isClosed ? AppColors.statusGreen : AppColors.error,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      elevation: 0,
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
