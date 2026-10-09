import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../backend/backend.dart';

class DepartmentItem {
  final String id;
  String name;
  String hospitalName;
  String roomNumber;
  String operatingHours;
  int defaultCapacity;
  bool isActive;

  DepartmentItem({
    required this.id,
    required this.name,
    required this.hospitalName,
    required this.roomNumber,
    required this.operatingHours,
    this.defaultCapacity = 25,
    this.isActive = true,
  });
}

class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({super.key});

  @override
  State<ManageDepartmentsScreen> createState() => _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final List<String> _defaultHospitalNames = [
    'National Hospital of Sri Lanka (NHSL)',
    'Colombo South Teaching Hospital (Kalubowila)',
    'Lady Ridgeway Hospital for Children (LRH)',
    'Colombo North Teaching Hospital (Ragama)',
  ];

  List<String> _hospitalNames = [];
  late String _selectedHospitalFilter;

  final List<DepartmentItem> _defaultDepartments = [
    DepartmentItem(
      id: 'dept_gen_med',
      name: 'General Medicine OPD',
      hospitalName: 'National Hospital of Sri Lanka (NHSL)',
      roomNumber: 'OPD Room 01',
      operatingHours: '8:00 AM - 12:00 PM',
      defaultCapacity: 25,
      isActive: true,
    ),
    DepartmentItem(
      id: 'dept_ent',
      name: 'ENT (Ear, Nose, Throat) Clinic',
      hospitalName: 'National Hospital of Sri Lanka (NHSL)',
      roomNumber: 'OPD Room 02',
      operatingHours: '8:00 AM - 12:00 PM',
      defaultCapacity: 25,
      isActive: true,
    ),
    DepartmentItem(
      id: 'dept_ortho',
      name: 'Orthopedics & Fracture Clinic',
      hospitalName: 'National Hospital of Sri Lanka (NHSL)',
      roomNumber: 'OPD Room 03',
      operatingHours: '8:30 AM - 01:00 PM',
      defaultCapacity: 25,
      isActive: true,
    ),
    DepartmentItem(
      id: 'dept_pedia',
      name: 'Pediatrics Clinic',
      hospitalName: 'Lady Ridgeway Hospital for Children (LRH)',
      roomNumber: 'OPD Room 04',
      operatingHours: '8:00 AM - 12:00 PM',
      defaultCapacity: 25,
      isActive: true,
    ),
    DepartmentItem(
      id: 'dept_cardio',
      name: 'Cardiology Clinic',
      hospitalName: 'National Hospital of Sri Lanka (NHSL)',
      roomNumber: 'OPD Room 05',
      operatingHours: '9:00 AM - 01:00 PM',
      defaultCapacity: 25,
      isActive: true,
    ),
  ];

  List<DepartmentItem> _departments = [];
  StreamSubscription<QuerySnapshot>? _hospitalsSub;
  StreamSubscription<QuerySnapshot>? _departmentsSub;

  @override
  void initState() {
    super.initState();
    _hospitalNames = List.from(_defaultHospitalNames);
    _selectedHospitalFilter = _hospitalNames.first;
    _departments = List.from(_defaultDepartments);
    _startRealtimeListeners();
  }

  @override
  void dispose() {
    _hospitalsSub?.cancel();
    _departmentsSub?.cancel();
    super.dispose();
  }

  void _startRealtimeListeners() {
    // 1. Listen to dynamic hospitals
    _hospitalsSub = FirebaseFirestore.instance
        .collection('hospitals')
        .snapshots()
        .listen((snapshot) {
      final Set<String> names = Set.from(_defaultHospitalNames);
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          names.add(name);
        }
      }

      if (mounted) {
        setState(() {
          _hospitalNames = names.toList();
          if (!_hospitalNames.contains(_selectedHospitalFilter) && _hospitalNames.isNotEmpty) {
            _selectedHospitalFilter = _hospitalNames.first;
          }
        });
      }
    });

    // 2. Listen to dynamic departments
    _departmentsSub = FirebaseFirestore.instance
        .collection('departments')
        .snapshots()
        .listen((snapshot) {
      final Map<String, DepartmentItem> map = {
        for (var d in _defaultDepartments) d.id: d,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final name = (data['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final hospName = (data['hospitalName'] ?? _selectedHospitalFilter).toString();
        final room = (data['roomNumber'] ?? 'OPD Room 01').toString();
        final hours = (data['operatingHours'] ?? '8:00 AM - 12:00 PM').toString();
        final cap = (data['capacityLimit'] is num) ? (data['capacityLimit'] as num).toInt() : 25;
        final isActive = data['isActive'] != false;

        map[id] = DepartmentItem(
          id: id,
          name: name,
          hospitalName: hospName,
          roomNumber: room,
          operatingHours: hours,
          defaultCapacity: cap,
          isActive: isActive,
        );
      }

      if (mounted) {
        setState(() {
          _departments = map.values.toList();
        });
      }
    });
  }

  void _showAddEditDepartmentDialog([DepartmentItem? existing]) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    String selectedHosp = (existing != null && _hospitalNames.contains(existing.hospitalName))
        ? existing.hospitalName
        : _selectedHospitalFilter;
    final roomController = TextEditingController(text: existing?.roomNumber ?? 'OPD Room 06');
    final hoursController = TextEditingController(text: existing?.operatingHours ?? '8:00 AM - 12:00 PM');
    int capacity = existing?.defaultCapacity ?? 25;
    bool isActive = existing?.isActive ?? true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit OPD Department' : 'Add OPD Department / Clinic',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),

                      // Hospital selector
                      const Text('Government Hospital *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _hospitalNames.contains(selectedHosp) ? selectedHosp : (_hospitalNames.isNotEmpty ? _hospitalNames.first : null),
                            isExpanded: true,
                            items: _hospitalNames.map((name) {
                              return DropdownMenuItem(
                                value: name,
                                child: Text(name, style: const TextStyle(fontSize: 13, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedHosp = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Department Name
                      const Text('Department / Clinic Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'e.g. Ophthalmology (Eye Clinic)',
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter department / clinic name';
                          }
                          if (val.trim().length < 3) {
                            return 'Department name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Room Number
                      const Text('Assigned Room / Unit *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: roomController,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'e.g. OPD Room 08',
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter assigned room / unit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Operating Hours
                      const Text('Operating Hours *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: hoursController,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'e.g. 8:00 AM - 12:00 PM',
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter clinic operating hours';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Slot Capacity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Max Capacity Per Time Slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              Text('Standard MOH cap is 25', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                                onPressed: capacity > 5
                                    ? () {
                                        setModalState(() {
                                          capacity -= 5;
                                        });
                                      }
                                    : null,
                              ),
                              Text('$capacity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                onPressed: capacity < 60
                                    ? () {
                                        setModalState(() {
                                          capacity += 5;
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Active Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Active for Patient Appointments', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          Switch(
                            value: isActive,
                            activeColor: AppColors.statusGreen,
                            onChanged: (val) {
                              setModalState(() {
                                isActive = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final name = nameController.text.trim();
                                  final room = roomController.text.trim();
                                  final hours = hoursController.text.trim();

                                  setModalState(() {
                                    isSubmitting = true;
                                  });

                                  final deptId = existing?.id ?? 'dept_${DateTime.now().millisecondsSinceEpoch}';

                                  // Save via dedicated HospitalAdminService
                                  final success = await HospitalAdminService().saveDepartment(
                                    id: deptId,
                                    name: name,
                                    hospitalName: selectedHosp,
                                    roomNumber: room,
                                    operatingHours: hours,
                                    capacityLimit: capacity,
                                    isActive: isActive,
                                  );

                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? (isEditing ? '$name updated successfully' : '$name added successfully')
                                            : 'Failed to save department to Firestore.',
                                      ),
                                      backgroundColor: success ? AppColors.statusGreen : AppColors.error,
                                    ),
                                  );
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  isEditing ? 'Save Changes' : 'Add OPD Department',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _departments.where((d) {
      final hospA = d.hospitalName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final hospB = _selectedHospitalFilter.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      return hospA.contains(hospB) || hospB.contains(hospA);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'OPD Clinics & Rooms',
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Clinic', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditDepartmentDialog(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              // Hospital Filter Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter by Hospital:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _hospitalNames.contains(_selectedHospitalFilter)
                              ? _selectedHospitalFilter
                              : (_hospitalNames.isNotEmpty ? _hospitalNames.first : null),
                          isExpanded: true,
                          items: _hospitalNames.map((name) {
                            return DropdownMenuItem(
                              value: name,
                              child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedHospitalFilter = val;
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

              // Clinics List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.medical_services_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 10),
                            const Text('No clinics configured for this hospital', style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                              onPressed: () => _showAddEditDepartmentDialog(),
                              child: const Text('Add First Clinic'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final dept = filtered[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textDark.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusOrange.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.meeting_room_rounded, color: AppColors.statusOrange, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dept.name,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${dept.roomNumber} • ${dept.operatingHours}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                      tooltip: 'Edit Clinic',
                                      onPressed: () => _showAddEditDepartmentDialog(dept),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Cap: ${dept.defaultCapacity} Patients / Slot',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: dept.isActive
                                            ? AppColors.statusGreen.withValues(alpha: 0.12)
                                            : AppColors.error.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        dept.isActive ? '● OPEN FOR BOOKINGS' : '● TEMPORARILY CLOSED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: dept.isActive ? AppColors.statusGreen : AppColors.error,
                                        ),
                                      ),
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
