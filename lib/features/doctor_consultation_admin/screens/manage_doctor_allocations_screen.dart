import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/consultation_admin_service.dart';

class ManageDoctorAllocationsScreen extends StatefulWidget {
  const ManageDoctorAllocationsScreen({super.key});

  @override
  State<ManageDoctorAllocationsScreen> createState() => _ManageDoctorAllocationsScreenState();
}

class _ManageDoctorAllocationsScreenState extends State<ManageDoctorAllocationsScreen> {
  final ConsultationAdminService _adminService = ConsultationAdminService();

  void _showAddEditAllocationDialog([DoctorRoomAllocation? existing]) {
    final isEditing = existing != null;

    final roomCtrl = TextEditingController(text: existing?.roomNumber ?? 'OPD Room 03');
    final doctorNameCtrl = TextEditingController(text: existing?.doctorName ?? '');
    final shiftCtrl = TextEditingController(text: existing?.shiftTime ?? '08:00 AM - 12:00 PM');
    final maxCapacityCtrl = TextEditingController(text: (existing?.maxPatients ?? 25).toString());

    String selectedHospital = existing?.hospitalId ?? 'nhsl';
    String selectedDepartment = existing?.departmentId ?? 'gen_med';
    String selectedStatus = existing?.status ?? 'active';

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
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                              child: Icon(
                                isEditing ? Icons.edit_calendar_rounded : Icons.person_add_alt_1_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEditing ? 'Edit Doctor Allocation' : 'Assign Doctor to OPD Room',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Room & Doctor Row
                    TextField(
                      controller: roomCtrl,
                      decoration: InputDecoration(
                        labelText: 'Consultation Room Number *',
                        hintText: 'e.g. OPD Consultation Room 03',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: doctorNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Assigned Doctor Name *',
                        hintText: 'e.g. Dr. H. M. Bandara',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hospital & Department Dropdowns
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: ['nhsl', 'hosp_kandy', 'hosp_karapitiya'].contains(selectedHospital) ? selectedHospital : 'nhsl',
                            decoration: InputDecoration(
                              labelText: 'Hospital',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'nhsl', child: Text('NHSL Colombo', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'hosp_kandy', child: Text('Kandy GH', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'hosp_karapitiya', child: Text('Karapitiya TH', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedHospital = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: ['gen_med', 'dept_pediatrics', 'dept_cardiology', 'dept_ent'].contains(selectedDepartment) ? selectedDepartment : 'gen_med',
                            decoration: InputDecoration(
                              labelText: 'Department',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'gen_med', child: Text('General Med', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'dept_pediatrics', child: Text('Pediatrics', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'dept_cardiology', child: Text('Cardiology', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'dept_ent', child: Text('ENT Clinic', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedDepartment = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Shift & Capacity
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: shiftCtrl,
                            decoration: InputDecoration(
                              labelText: 'Consultation Shift Hours',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: maxCapacityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Slot Limit',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Room Availability Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active (Consulting Patients)')),
                        DropdownMenuItem(value: 'on_break', child: Text('On Break (Temporary Hold)')),
                        DropdownMenuItem(value: 'closed', child: Text('Closed / Off-Duty')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            onPressed: () async {
                              final room = roomCtrl.text.trim();
                              final doctor = doctorNameCtrl.text.trim();
                              if (room.isEmpty || doctor.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill Room Number and Doctor Name.')),
                                );
                                return;
                              }

                              final allocId = existing?.id ?? 'ALLOC-${DateTime.now().millisecondsSinceEpoch % 10000}';
                              final capacity = int.tryParse(maxCapacityCtrl.text.trim()) ?? 25;

                              final record = DoctorRoomAllocation(
                                id: allocId,
                                roomNumber: room,
                                doctorName: doctor,
                                doctorUid: existing?.doctorUid ?? 'doc-${DateTime.now().millisecondsSinceEpoch % 1000}',
                                hospitalId: selectedHospital,
                                hospitalName: selectedHospital == 'nhsl' ? 'National Hospital of Sri Lanka' : (selectedHospital == 'hosp_kandy' ? 'Kandy General Hospital' : 'Karapitiya Teaching Hospital'),
                                departmentId: selectedDepartment,
                                departmentName: selectedDepartment == 'gen_med' ? 'General Medicine OPD' : (selectedDepartment == 'dept_pediatrics' ? 'Pediatrics OPD' : (selectedDepartment == 'dept_cardiology' ? 'Cardiology OPD' : 'ENT Clinic')),
                                shiftTime: shiftCtrl.text.trim(),
                                maxPatients: capacity,
                                isActive: selectedStatus == 'active',
                                status: selectedStatus,
                              );

                              Navigator.pop(context);

                              final success = isEditing
                                  ? await _adminService.updateAllocation(record)
                                  : await _adminService.createAllocation(record);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Doctor room allocation saved successfully!' : 'Failed to save allocation.'),
                                    backgroundColor: success ? AppColors.success : AppColors.error,
                                  ),
                                );
                              }
                            },
                            child: Text(isEditing ? 'Save Changes' : 'Assign Doctor'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAllocation(DoctorRoomAllocation a) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Unassign Doctor Room'),
        content: Text('Are you sure you want to remove the room allocation for ${a.doctorName} in ${a.roomNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await _adminService.deleteAllocation(a.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Allocation removed successfully!' : 'Failed to remove.'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor & Room Allocations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Allocation',
            onPressed: () => _showAddEditAllocationDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Assign Room', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditAllocationDialog(),
      ),
      body: SafeArea(
        child: StreamBuilder<List<DoctorRoomAllocation>>(
          stream: _adminService.streamDoctorAllocations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allocations = snapshot.data ?? [];
            if (allocations.isEmpty) {
              return const Center(child: Text('No Doctor Room Allocations recorded.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: allocations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final a = allocations[index];
                final isActive = a.status == 'active';

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isActive ? AppColors.primaryLight : AppColors.neutralLight,
                              child: Icon(Icons.meeting_room_rounded, color: isActive ? AppColors.primary : AppColors.neutral),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.roomNumber,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                  ),
                                  Text(
                                    '${a.doctorName} • ${a.departmentName}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(a.status),
                          ],
                        ),
                        const Divider(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(a.shiftTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text('Max: ${a.maxPatients} Patients', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showAddEditAllocationDialog(a),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit Allocation', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              onPressed: () => _confirmDeleteAllocation(a),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'active':
        bg = AppColors.statusGreenLight;
        fg = AppColors.statusGreen;
        label = 'Active';
        break;
      case 'on_break':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = 'On Break';
        break;
      default:
        bg = AppColors.neutralLight;
        fg = AppColors.neutral;
        label = 'Closed';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
