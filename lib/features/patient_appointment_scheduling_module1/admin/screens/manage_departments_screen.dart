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
  String _selectedHospitalFilter = '';

  List<DepartmentItem> _departments = [];
  StreamSubscription<QuerySnapshot>? _hospitalsSub;
  StreamSubscription<QuerySnapshot>? _departmentsSub;

  @override
  void initState() {
    super.initState();
    _hospitalNames = List.from(_defaultHospitalNames);
    _selectedHospitalFilter = _hospitalNames.first;
    _departments = [];
    _startRealtimeListeners();
  }

  @override
  void dispose() {
    _hospitalsSub?.cancel();
    _departmentsSub?.cancel();
    super.dispose();
  }

  void _startRealtimeListeners() {
    // 1. Listen to dynamic hospitals in real-time
    _hospitalsSub = FirebaseFirestore.instance
        .collection('hospitals')
        .snapshots()
        .listen((snapshot) {
      final List<String> names = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().trim();
        if (name.isNotEmpty && !names.contains(name)) {
          names.add(name);
        }
      }

      // If no hospitals yet in Firestore, use default names
      if (names.isEmpty) {
        names.addAll(_defaultHospitalNames);
      }

      if (mounted) {
        setState(() {
          _hospitalNames = names;
          if (!_hospitalNames.contains(_selectedHospitalFilter) && _hospitalNames.isNotEmpty) {
            _selectedHospitalFilter = _hospitalNames.first;
          }
        });
      }
    });

    // 2. Listen to dynamic departments in real-time
    _departmentsSub = FirebaseFirestore.instance
        .collection('departments')
        .snapshots()
        .listen((snapshot) {
      final List<DepartmentItem> list = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final name = (data['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        String hospName = (data['hospitalName'] ?? '').toString().trim();
        final hospId = (data['hospitalId'] ?? '').toString().trim();
        if (hospName.isEmpty && hospId.isNotEmpty) {
          for (var hName in _hospitalNames) {
            final cleanH = hName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            final cleanId = hospId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            if (cleanH.contains(cleanId) || cleanId.contains(cleanH)) {
              hospName = hName;
              break;
            }
          }
        }

        final room = (data['roomNumber'] ?? 'OPD Room 01').toString();
        final hours = (data['operatingHours'] ?? '8:00 AM - 12:00 PM').toString();
        final cap = (data['capacityLimit'] is num) ? (data['capacityLimit'] as num).toInt() : 25;
        final isActive = data['isActive'] != false;

        list.add(DepartmentItem(
          id: id,
          name: name,
          hospitalName: hospName,
          roomNumber: room,
          operatingHours: hours,
          defaultCapacity: cap,
          isActive: isActive,
        ));
      }

      if (mounted) {
        setState(() {
          _departments = list;
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
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          '8:00 AM - 12:00 PM',
                          '8:00 AM - 01:00 PM',
                          '8:00 AM - 02:00 PM',
                          '12:00 PM - 04:00 PM',
                        ].map((preset) {
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                hoursController.text = preset;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: hoursController.text == preset
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: hoursController.text == preset
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                preset,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: hoursController.text == preset ? FontWeight.bold : FontWeight.normal,
                                  color: hoursController.text == preset ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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

                      if (isEditing) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                            label: const Text('Delete Clinic', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDeleteDepartment(existing);
                            },
                          ),
                        ),
                      ],
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

  void _confirmDeleteDepartment(DepartmentItem dept) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Delete Clinic / Department', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text('Are you sure you want to delete "${dept.name}" from ${dept.hospitalName}? Patients will no longer see this clinic.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await HospitalAdminService().deleteDepartment(dept.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '${dept.name} deleted successfully!' : 'Failed to delete clinic.'),
                    backgroundColor: success ? AppColors.statusGreen : AppColors.error,
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _confirmCleanAllTestDepartments() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.cleaning_services_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text('Clean Duplicate Clinics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text('This will remove duplicate clinic entries for "$_selectedHospitalFilter" and clean up test clinics. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final count = await HospitalAdminService().cleanupDuplicateDepartments(hospitalName: _selectedHospitalFilter);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(count > 0 ? '$count duplicate clinics removed successfully!' : 'No duplicates found to clean.'),
                    backgroundColor: AppColors.statusGreen,
                  ),
                );
              },
              child: const Text('Clean Duplicates'),
            ),
          ],
        );
      },
    );
  }

  void _confirmPopulateStandardClinics() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.medical_services_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text('Auto-Populate Clinics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text('This will generate all standard OPD clinics (General Medicine, Pediatrics, Cardiology, Ophthalmology, ENT, Dental, Orthopedics) for "$_selectedHospitalFilter". Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final count = await HospitalAdminService().populateStandardClinics(
                  hospitalName: _selectedHospitalFilter,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(count > 0 ? '$count standard OPD clinics added successfully!' : 'Failed to populate clinics.'),
                    backgroundColor: AppColors.statusGreen,
                  ),
                );
              },
              child: const Text('Populate Clinics'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _departments.where((d) {
      if (d.hospitalName.trim().isEmpty) return false;
      final hospA = d.hospitalName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final hospB = _selectedHospitalFilter.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (hospA.isEmpty || hospB.isEmpty) return false;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check_rounded, color: Colors.white),
            tooltip: 'Auto-Populate Standard Clinics',
            onPressed: _confirmPopulateStandardClinics,
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white),
            tooltip: 'Clean Duplicate Clinics',
            onPressed: _confirmCleanAllTestDepartments,
          ),
        ],
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                                  label: const Text('Populate Standard Clinics'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                                  onPressed: _confirmPopulateStandardClinics,
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Add Custom Clinic'),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                                  onPressed: () => _showAddEditDepartmentDialog(),
                                ),
                              ],
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
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                                      tooltip: 'Delete Clinic',
                                      onPressed: () => _confirmDeleteDepartment(dept),
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
