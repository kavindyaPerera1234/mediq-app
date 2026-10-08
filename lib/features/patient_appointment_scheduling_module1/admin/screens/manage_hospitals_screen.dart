import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../backend/backend.dart';

class HospitalItem {
  final String id;
  String name;
  String district;
  String address;
  String phone;
  bool isActive;

  HospitalItem({
    required this.id,
    required this.name,
    required this.district,
    required this.address,
    required this.phone,
    this.isActive = true,
  });
}

class ManageHospitalsScreen extends StatefulWidget {
  const ManageHospitalsScreen({super.key});

  @override
  State<ManageHospitalsScreen> createState() => _ManageHospitalsScreenState();
}

class _ManageHospitalsScreenState extends State<ManageHospitalsScreen> {
  final List<HospitalItem> _hospitals = [
    HospitalItem(
      id: 'hosp_nhsl',
      name: 'National Hospital of Sri Lanka (NHSL)',
      district: 'Colombo',
      address: 'Regent Street, Colombo 10',
      phone: '011-2691111',
      isActive: true,
    ),
    HospitalItem(
      id: 'hosp_csth',
      name: 'Colombo South Teaching Hospital (Kalubowila)',
      district: 'Colombo',
      address: 'Hospital Road, Kalubowila',
      phone: '011-2763060',
      isActive: true,
    ),
    HospitalItem(
      id: 'hosp_lrh',
      name: 'Lady Ridgeway Hospital for Children (LRH)',
      district: 'Colombo',
      address: 'Dr. Danister De Silva Mawatha, Colombo 08',
      phone: '011-2693711',
      isActive: true,
    ),
    HospitalItem(
      id: 'hosp_cnth',
      name: 'Colombo North Teaching Hospital (Ragama)',
      district: 'Gampaha',
      address: 'Ragama Road, Ragama',
      phone: '011-2958271',
      isActive: true,
    ),
  ];

  void _showAddEditHospitalDialog([HospitalItem? existing]) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final districtController = TextEditingController(text: existing?.district ?? 'Colombo');
    final addressController = TextEditingController(text: existing?.address ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    bool isActive = existing?.isActive ?? true;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Hospital' : 'Register New Hospital',
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

                    // Hospital Name
                    const Text('Hospital Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Teaching Hospital Kandy',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // District
                    const Text('District', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: districtController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Colombo, Kandy, Galle',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Address
                    const Text('Location / Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        hintText: 'e.g. William Gopallawa Mawatha, Kandy',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone Hotline
                    const Text('OPD Hotline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g. 081-2222261',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Active Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Active for OPD Bookings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final district = districtController.text.trim();
                          final address = addressController.text.trim();
                          final phone = phoneController.text.trim();

                          if (name.isEmpty) return;

                          if (isEditing) {
                            setState(() {
                              existing.name = name;
                              existing.district = district;
                              existing.address = address;
                              existing.phone = phone;
                              existing.isActive = isActive;
                            });
                          } else {
                            final newHosp = HospitalItem(
                              id: 'hosp_${DateTime.now().millisecondsSinceEpoch}',
                              name: name,
                              district: district,
                              address: address,
                              phone: phone,
                              isActive: isActive,
                            );
                            setState(() {
                              _hospitals.add(newHosp);
                            });
                          }

                          // Save via dedicated HospitalAdminService
                          await HospitalAdminService().saveHospital(
                            id: existing?.id ?? 'hosp_${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            district: district,
                            address: address,
                            phone: phone,
                            isActive: isActive,
                          );

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Hospital updated successfully' : 'Hospital registered successfully'),
                              backgroundColor: AppColors.statusGreen,
                            ),
                          );
                        },
                        child: Text(isEditing ? 'Save Changes' : 'Register Hospital'),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Manage Government Hospitals',
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
        label: const Text('Add Hospital'),
        onPressed: () => _showAddEditHospitalDialog(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: _hospitals.length,
            itemBuilder: (context, index) {
              final hosp = _hospitals[index];
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hosp.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${hosp.district} • ${hosp.address}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    hosp.phone,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                          onPressed: () => _showAddEditHospitalDialog(hosp),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hosp.isActive
                                ? AppColors.statusGreen.withValues(alpha: 0.12)
                                : AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hosp.isActive ? '● OPD ACTIVE' : '● CLOSED / INACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hosp.isActive ? AppColors.statusGreen : AppColors.error,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showAddEditHospitalDialog(hosp),
                          child: const Text('Edit Settings →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
