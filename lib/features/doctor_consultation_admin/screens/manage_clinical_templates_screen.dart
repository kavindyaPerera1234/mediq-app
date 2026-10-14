import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/consultation_admin_service.dart';

class ManageClinicalTemplatesScreen extends StatefulWidget {
  const ManageClinicalTemplatesScreen({super.key});

  @override
  State<ManageClinicalTemplatesScreen> createState() => _ManageClinicalTemplatesScreenState();
}

class _ManageClinicalTemplatesScreenState extends State<ManageClinicalTemplatesScreen> {
  final ConsultationAdminService _adminService = ConsultationAdminService();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'General OPD',
    'Cardiology',
    'Pediatrics',
    'Respiratory',
    'Endocrinology',
  ];

  void _showAddEditTemplateDialog([ClinicalTemplate? existing]) {
    final isEditing = existing != null;

    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final icdCtrl = TextEditingController(text: existing?.icdCode ?? '');
    final symptomsCtrl = TextEditingController(text: existing?.symptoms ?? '');
    final diagnosisCtrl = TextEditingController(text: existing?.standardDiagnosis ?? '');
    final rxCtrl = TextEditingController(text: existing?.defaultPrescription ?? '');
    final dosageCtrl = TextEditingController(text: existing?.dosageInstructions ?? '');

    String selectedCat = existing?.category ?? 'General OPD';

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
                                isEditing ? Icons.edit_document : Icons.note_add_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEditing ? 'Edit Clinical Template' : 'Add Clinical Template (CRUD)',
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

                    // Title & Category
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: titleCtrl,
                            decoration: InputDecoration(
                              labelText: 'Template Name *',
                              hintText: 'e.g. Acute Tonsillitis',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCat,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: _categories.where((c) => c != 'All').map((cat) {
                              return DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedCat = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ICD Code & Standard Diagnosis
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: icdCtrl,
                            decoration: InputDecoration(
                              labelText: 'ICD-10 Code',
                              hintText: 'e.g. J03.9',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: diagnosisCtrl,
                            decoration: InputDecoration(
                              labelText: 'Standard Diagnosis Text *',
                              hintText: 'e.g. Acute Follicular Tonsillitis',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Symptoms
                    TextField(
                      controller: symptomsCtrl,
                      decoration: InputDecoration(
                        labelText: 'Presenting Clinical Symptoms',
                        hintText: 'e.g. Odynophagia, tonsillar exudates, fever',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Prescription
                    TextField(
                      controller: rxCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Standard Prescription Regimen *',
                        hintText: 'e.g. Phenoxymethylpenicillin 500mg QDS x 10 days\nParacetamol 500mg TDS PRN',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dosage & Advice
                    TextField(
                      controller: dosageCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Dosage & Patient Care Advice',
                        hintText: 'e.g. Complete antibiotic course. Warm saline gargles.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Buttons
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
                              final title = titleCtrl.text.trim();
                              final diag = diagnosisCtrl.text.trim();
                              final rx = rxCtrl.text.trim();

                              if (title.isEmpty || diag.isEmpty || rx.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill Template Name, Diagnosis and Prescription.')),
                                );
                                return;
                              }

                              final tplId = existing?.id ?? 'TPL-${DateTime.now().millisecondsSinceEpoch % 10000}';
                              final record = ClinicalTemplate(
                                id: tplId,
                                title: title,
                                icdCode: icdCtrl.text.trim().isNotEmpty ? icdCtrl.text.trim() : 'ICD-OPD',
                                symptoms: symptomsCtrl.text.trim(),
                                standardDiagnosis: diag,
                                defaultPrescription: rx,
                                dosageInstructions: dosageCtrl.text.trim(),
                                category: selectedCat,
                              );

                              Navigator.pop(context);

                              final success = isEditing
                                  ? await _adminService.updateTemplate(record)
                                  : await _adminService.createTemplate(record);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Clinical template saved successfully!' : 'Failed to save template.'),
                                    backgroundColor: success ? AppColors.success : AppColors.error,
                                  ),
                                );
                              }
                            },
                            child: Text(isEditing ? 'Save Changes' : 'Create Template'),
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

  void _confirmDeleteTemplate(ClinicalTemplate t) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Clinical Template'),
        content: Text('Are you sure you want to delete template "${t.title}" (${t.icdCode})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await _adminService.deleteTemplate(t.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Template deleted successfully!' : 'Failed to delete.'),
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
        title: const Text('Prescription & Diagnosis Templates', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Template',
            onPressed: () => _showAddEditTemplateDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Template', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditTemplateDialog(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Chips Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Templates List
            Expanded(
              child: StreamBuilder<List<ClinicalTemplate>>(
                stream: _adminService.streamClinicalTemplates(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allTemplates = snapshot.data ?? [];
                  final filtered = allTemplates.where((t) {
                    if (_selectedCategory != 'All' && t.category != _selectedCategory) return false;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No Clinical Templates found.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final t = filtered[index];
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t.icdCode,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      t.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.chipBackground, borderRadius: BorderRadius.circular(6)),
                                    child: Text(t.category, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              Text('Diagnosis: ${t.standardDiagnosis}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 6),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Standard Prescription Regimen:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(t.defaultPrescription, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                    if (t.dosageInstructions.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Advice: ${t.dosageInstructions}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showAddEditTemplateDialog(t),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Edit Template', style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                    onPressed: () => _confirmDeleteTemplate(t),
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
          ],
        ),
      ),
    );
  }
}
