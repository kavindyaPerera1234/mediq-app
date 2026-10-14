import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/consultation.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/consultation_admin_service.dart';

class ManageConsultationsScreen extends StatefulWidget {
  final AuthService? authService;

  const ManageConsultationsScreen({super.key, this.authService});

  @override
  State<ManageConsultationsScreen> createState() => _ManageConsultationsScreenState();
}

class _ManageConsultationsScreenState extends State<ManageConsultationsScreen> {
  final ConsultationAdminService _adminService = ConsultationAdminService();

  String _searchQuery = '';
  String _selectedStatusFilter = 'all'; // 'all', 'in_progress', 'completed', 'cancelled'
  String _selectedHospitalFilter = 'all'; // 'all', 'nhsl', 'hosp_kandy', 'hosp_karapitiya'

  final List<Map<String, String>> _hospitalOptions = [
    {'id': 'all', 'name': 'All Hospitals'},
    {'id': 'nhsl', 'name': 'National Hospital of Sri Lanka (NHSL)'},
    {'id': 'hosp_kandy', 'name': 'Kandy General Hospital'},
    {'id': 'hosp_karapitiya', 'name': 'Karapitiya Teaching Hospital'},
  ];

  // ==========================================
  // CREATE / UPDATE DIALOG
  // ==========================================
  void _showAddEditConsultationDialog([Consultation? existing]) {
    final isEditing = existing != null;

    final patientNameCtrl = TextEditingController(text: existing?.patientName ?? '');
    final tokenCtrl = TextEditingController(text: existing?.tokenNumber ?? '');
    final doctorNameCtrl = TextEditingController(text: existing?.doctorName ?? 'Dr. S. Perera');
    final diagnosisCtrl = TextEditingController(text: existing?.diagnosis ?? '');
    final prescriptionCtrl = TextEditingController(text: existing?.prescription ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    String selectedHospital = existing?.hospitalId ?? 'nhsl';
    String selectedDepartment = existing?.departmentId ?? 'gen_med';
    String selectedStatus = existing?.status ?? 'in_progress';
    String selectedPriority = existing?.priority ?? 'normal';

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
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEditing ? 'Edit Clinical Consultation' : 'Add New Consultation (CRUD)',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
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

                    // Patient & Token Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: patientNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Patient Full Name *',
                              hintText: 'e.g. Kasun Silva',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: tokenCtrl,
                            decoration: InputDecoration(
                              labelText: 'Token *',
                              hintText: 'e.g. A-027',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Hospital & Clinic Selectors
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: ['nhsl', 'hosp_kandy', 'hosp_karapitiya'].contains(selectedHospital)
                                ? selectedHospital
                                : 'nhsl',
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
                            value: ['gen_med', 'dept_pediatrics', 'dept_cardiology', 'dept_ent'].contains(selectedDepartment)
                                ? selectedDepartment
                                : 'gen_med',
                            decoration: InputDecoration(
                              labelText: 'OPD Clinic',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'gen_med', child: Text('Gen Medicine', overflow: TextOverflow.ellipsis)),
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

                    // Attending Doctor & Priority
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: doctorNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Attending Doctor',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedPriority,
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'normal', child: Text('Normal')),
                              DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                              DropdownMenuItem(value: 'elderly', child: Text('Elderly')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedPriority = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Selector
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Consultation Lifecycle Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'in_progress', child: Text('In Progress (Active in Clinic)')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed (Discharged)')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled / No Show')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Diagnosis
                    TextField(
                      controller: diagnosisCtrl,
                      decoration: InputDecoration(
                        labelText: 'Clinical Diagnosis / ICD Summary',
                        hintText: 'e.g. Acute Viral Pharyngitis / Hypertension Stage 1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Prescription
                    TextField(
                      controller: prescriptionCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Prescription & Medication Dosage',
                        hintText: 'e.g. Paracetamol 500mg TDS x 3 days\nAmoxicillin 500mg TDS x 5 days',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Clinical Notes
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Clinical Observations / Notes',
                        hintText: 'e.g. Patient advised adequate oral hydration and review in 5 days.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons (Save / Cancel)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final name = patientNameCtrl.text.trim();
                              final token = tokenCtrl.text.trim();

                              if (name.isEmpty || token.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill patient name and token number.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              final patientId = existing?.patientId ?? 'pat-${DateTime.now().millisecondsSinceEpoch % 10000}';
                              final consultationId = existing?.consultationId ?? 'CNS-$patientId';

                              final newRecord = Consultation(
                                consultationId: consultationId,
                                appointmentId: existing?.appointmentId ?? 'APT-$patientId',
                                queueEntryId: existing?.queueEntryId ?? 'QE-$patientId',
                                patientId: patientId,
                                patientName: name,
                                doctorId: existing?.doctorId ?? 'doc-silva-uid',
                                doctorName: doctorNameCtrl.text.trim().isNotEmpty ? doctorNameCtrl.text.trim() : 'Dr. S. Perera',
                                tokenNumber: token,
                                hospitalId: selectedHospital,
                                departmentId: selectedDepartment,
                                status: selectedStatus,
                                diagnosis: diagnosisCtrl.text.trim(),
                                prescription: prescriptionCtrl.text.trim(),
                                notes: notesCtrl.text.trim(),
                                priority: selectedPriority,
                                startedAt: existing?.startedAt ?? DateTime.now(),
                                completedAt: selectedStatus == 'completed' ? (existing?.completedAt ?? DateTime.now()) : null,
                              );

                              Navigator.pop(context);

                              final success = isEditing
                                  ? await _adminService.updateConsultation(newRecord)
                                  : await _adminService.createConsultation(newRecord);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? (isEditing ? 'Consultation record updated successfully!' : 'New consultation created successfully!')
                                          : 'Failed to save consultation.',
                                    ),
                                    backgroundColor: success ? AppColors.success : AppColors.error,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              isEditing ? 'Save Changes' : 'Create Consultation',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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

  // ==========================================
  // VIEW CONSULTATION DETAILS MODAL
  // ==========================================
  void _showConsultationDetailsModal(Consultation c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Clinical Consultation Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          Text(c.consultationId, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
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

              // Patient Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c.tokenNumber.isNotEmpty ? c.tokenNumber : 'TOKEN',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.patientName.isNotEmpty ? c.patientName : 'Unknown Patient',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Doctor: ${c.doctorName.isNotEmpty ? c.doctorName : 'Medical Officer'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusPill(c.status),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Clinical Diagnosis
              _buildDetailRow('Clinical Diagnosis', c.diagnosis.isNotEmpty ? c.diagnosis : 'Not recorded', Icons.medical_services_outlined),
              const SizedBox(height: 12),

              // Prescription
              _buildDetailRow('Prescription & Medication', c.prescription.isNotEmpty ? c.prescription : 'No medications prescribed', Icons.medication_rounded),
              const SizedBox(height: 12),

              // Observations & Clinical Notes
              _buildDetailRow('Clinical Notes / Advice', c.notes.isNotEmpty ? c.notes : 'Routine clinical examination conducted.', Icons.notes_rounded),
              const SizedBox(height: 16),

              // Timestamps
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    c.startedAt != null ? 'Started: ${DateFormat('yyyy-MM-dd HH:mm').format(c.startedAt!)}' : 'Started: Today',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (c.completedAt != null)
                    Text(
                      'Completed: ${DateFormat('HH:mm').format(c.completedAt!)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.statusGreen, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons: Edit or Close
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddEditConsultationDialog(c);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Record'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // DELETE CONFIRMATION DIALOG
  // ==========================================
  void _confirmDeleteConsultation(Consultation c) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Consultation Record'),
        content: Text(
          'Are you sure you want to delete consultation for ${c.patientName} (Token ${c.tokenNumber})?\n\nThis will remove the clinical consultation record from Cloud Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await _adminService.deleteConsultation(c.consultationId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Consultation record deleted successfully!' : 'Failed to delete record.'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
        title: const Text(
          'Manage Clinical Consultations',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
            tooltip: 'Add Consultation',
            onPressed: () => _showAddEditConsultationDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Consultation', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditConsultationDialog(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Header Container
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patient name or token (e.g. A-019)...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Hospital Dropdown Filter
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedHospitalFilter,
                            isDense: true,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            items: _hospitalOptions.map((h) {
                              return DropdownMenuItem(value: h['id'], child: Text(h['name']!));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedHospitalFilter = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Statuses', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('In Progress', 'in_progress'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Completed', 'completed'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Cancelled', 'cancelled'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Stream List View
            Expanded(
              child: StreamBuilder<List<Consultation>>(
                stream: _adminService.streamConsultations(
                  hospitalId: _selectedHospitalFilter,
                  statusFilter: _selectedStatusFilter,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allConsultations = snapshot.data ?? [];
                  final filtered = allConsultations.where((c) {
                    if (_searchQuery.isNotEmpty) {
                      final matchesName = c.patientName.toLowerCase().contains(_searchQuery);
                      final matchesToken = c.tokenNumber.toLowerCase().contains(_searchQuery);
                      final matchesDiagnosis = c.diagnosis.toLowerCase().contains(_searchQuery);
                      if (!matchesName && !matchesToken && !matchesDiagnosis) return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off_rounded, size: 54, color: AppColors.textMuted.withValues(alpha: 0.6)),
                          const SizedBox(height: 14),
                          const Text(
                            'No Consultation Records Found',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Click "New Consultation" below to add a record.',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      return _buildConsultationCard(c);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedStatusFilter = value;
        });
      },
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildConsultationCard(Consultation c) {
    final isEmergency = c.priority == 'emergency';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isEmergency ? AppColors.error.withValues(alpha: 0.5) : AppColors.border,
          width: isEmergency ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Token, Patient, Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isEmergency ? AppColors.error : AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c.tokenNumber.isNotEmpty ? c.tokenNumber : 'TOKEN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.patientName.isNotEmpty ? c.patientName : 'Walk-in Patient',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                      ),
                      Text(
                        'Dr: ${c.doctorName.isNotEmpty ? c.doctorName : "Medical Officer"} • ${_getDepartmentName(c.departmentId)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(c.status),
              ],
            ),
            const Divider(height: 18),

            // Diagnosis preview
            if (c.diagnosis.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Diagnosis: ${c.diagnosis}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Prescription snippet
            if (c.prescription.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medication_outlined, size: 16, color: AppColors.statusGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Rx: ${c.prescription.replaceAll('\n', ' • ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Card Action Buttons (View, Edit, Delete)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showConsultationDetailsModal(c),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text('View Details', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
                TextButton.icon(
                  onPressed: () => _showAddEditConsultationDialog(c),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.info),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  tooltip: 'Delete Consultation',
                  onPressed: () => _confirmDeleteConsultation(c),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'completed':
        bg = AppColors.statusGreenLight;
        fg = AppColors.statusGreen;
        label = 'Completed';
        break;
      case 'in_progress':
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        label = 'In Progress';
        break;
      case 'cancelled':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = 'Cancelled';
        break;
      default:
        bg = AppColors.neutralLight;
        fg = AppColors.neutral;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildDetailRow(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3)),
        ],
      ),
    );
  }

  String _getDepartmentName(String deptId) {
    switch (deptId) {
      case 'gen_med':
        return 'General Medicine';
      case 'dept_pediatrics':
        return 'Pediatrics';
      case 'dept_cardiology':
        return 'Cardiology';
      case 'dept_ent':
        return 'ENT Clinic';
      default:
        return 'General OPD';
    }
  }
}
