import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  static const List<String> sriLankaDistricts = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Matale',
    'Nuwara Eliya',
    'Galle',
    'Matara',
    'Hambantota',
    'Jaffna',
    'Kilinochchi',
    'Mannar',
    'Vavuniya',
    'Mullaitivu',
    'Batticaloa',
    'Ampara',
    'Trincomalee',
    'Kurunegala',
    'Puttalam',
    'Anuradhapura',
    'Polonnaruwa',
    'Badulla',
    'Monaragala',
    'Ratnapura',
    'Kegalle',
  ];

  final List<HospitalItem> _defaultHospitals = [
    HospitalItem(
      id: 'nhsl',
      name: 'National Hospital of Sri Lanka (NHSL)',
      district: 'Colombo',
      address: 'Regent Street, Colombo 10',
      phone: '011-2691111',
      isActive: true,
    ),
    HospitalItem(
      id: 'csth',
      name: 'Colombo South Teaching Hospital (Kalubowila)',
      district: 'Colombo',
      address: 'Hospital Road, Kalubowila',
      phone: '011-2763060',
      isActive: true,
    ),
    HospitalItem(
      id: 'lrh',
      name: 'Lady Ridgeway Hospital for Children (LRH)',
      district: 'Colombo',
      address: 'Dr. Danister De Silva Mawatha, Colombo 08',
      phone: '011-2693711',
      isActive: true,
    ),
    HospitalItem(
      id: 'cnth',
      name: 'Colombo North Teaching Hospital (Ragama)',
      district: 'Gampaha',
      address: 'Ragama Road, Ragama',
      phone: '011-2958271',
      isActive: true,
    ),
  ];

  List<HospitalItem> _hospitals = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _hospitalsSub;

  @override
  void initState() {
    super.initState();
    _hospitals = List.from(_defaultHospitals);
    _listenToHospitals();
  }

  @override
  void dispose() {
    _hospitalsSub?.cancel();
    super.dispose();
  }

  void _listenToHospitals() {
    _hospitalsSub = FirebaseFirestore.instance
        .collection('hospitals')
        .snapshots()
        .listen((snapshot) {
      final Map<String, HospitalItem> map = {};

      // 1. Load from Firestore
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final name = (data['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final district = (data['district'] ?? 'Colombo').toString();
        final address = (data['address'] ?? data['location'] ?? '').toString();
        final phone = (data['phone'] ?? '').toString();
        final isActive = data['isActive'] == true || data['isOpdAvailable'] == true;

        map[id] = HospitalItem(
          id: id,
          name: name,
          district: district,
          address: address,
          phone: phone,
          isActive: isActive,
        );
      }

      // 2. Add default hospitals only if not already saved in Firestore (deduplicate)
      for (var def in _defaultHospitals) {
        final defClean = def.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final alreadyExists = map.values.any((h) {
          final hClean = h.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          return h.id == def.id || hClean.contains(defClean) || defClean.contains(hClean);
        });
        if (!alreadyExists && !map.containsKey(def.id)) {
          map[def.id] = def;
        }
      }

      if (mounted) {
        setState(() {
          _hospitals = map.values.toList();
          _isLoading = false;
        });
      }
    }, onError: (e) {
      debugPrint('Error listening to hospitals: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _confirmDeleteHospital(HospitalItem hosp) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Delete Hospital', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${hosp.name}"? This hospital will be permanently removed from the patient app.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() {
                _hospitals.removeWhere((h) => h.id == hosp.id);
              });
              final success = await HospitalAdminService().deleteHospital(hosp.id, hospitalName: hosp.name);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? '"${hosp.name}" deleted successfully' : 'Failed to delete hospital'),
                  backgroundColor: success ? AppColors.statusGreen : AppColors.error,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmCleanAllTestHospitals() {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: AppColors.statusOrange, size: 24),
            SizedBox(width: 8),
            Text('Clean Test Hospitals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all "test" hospitals created during testing? This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final deletedCount = await HospitalAdminService().cleanupTestHospitals();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Cleaned $deletedCount test hospital(s) successfully!'),
                  backgroundColor: AppColors.statusGreen,
                ),
              );
            },
            child: const Text('Clean All Test Entries', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddEditHospitalDialog([HospitalItem? existing]) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    String selectedDistrict = (existing != null && sriLankaDistricts.contains(existing.district))
        ? existing.district
        : 'Colombo';
    final addressController = TextEditingController(text: existing?.address ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
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
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isEditing ? Icons.edit_location_alt_rounded : Icons.add_business_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isEditing ? 'Edit Hospital' : 'Register New Hospital',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            ],
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
                      const Text('Hospital Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'e.g. Teaching Hospital Kandy',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.local_hospital_outlined, size: 18, color: AppColors.primary),
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
                            return 'Please enter hospital name';
                          }
                          if (val.trim().length < 3) {
                            return 'Hospital name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // District Dropdown Selector (User Friendly)
                      const Text('District (Sri Lanka) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
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
                            value: selectedDistrict,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500),
                            items: sriLankaDistricts.map((district) {
                              return DropdownMenuItem<String>(
                                value: district,
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_city_rounded, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 8),
                                    Text(district, style: const TextStyle(color: AppColors.textDark)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedDistrict = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Address
                      const Text('Location / Address *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: addressController,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'e.g. William Gopallawa Mawatha, Kandy',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
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
                            return 'Please enter location / address';
                          }
                          if (val.trim().length < 4) {
                            return 'Address must be at least 4 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Phone Hotline
                      const Text('OPD Hotline Phone *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'e.g. 081-2222261 or 0112691111',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.primary),
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
                            return 'Please enter OPD hotline phone number';
                          }
                          final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.length < 9 || digits.length > 12) {
                            return 'Please enter a valid phone number (e.g. 081-2222261)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Active Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Active for OPD Bookings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              Text('Visible to patients on mobile app', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
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
                                  final district = selectedDistrict;
                                  final address = addressController.text.trim();
                                  final phone = phoneController.text.trim();

                                  setModalState(() {
                                    isSubmitting = true;
                                  });

                                  final hospitalId = existing?.id ?? 'hosp_${DateTime.now().millisecondsSinceEpoch}';

                                  // 1. Save directly to Cloud Firestore
                                  final success = await HospitalAdminService().saveHospital(
                                    id: hospitalId,
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
                                      content: Text(
                                        success
                                            ? (isEditing ? '$name updated successfully!' : '$name registered successfully!')
                                            : 'Failed to save hospital to Firestore.',
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
                                  isEditing ? 'Save Changes' : 'Register Hospital',
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
                          label: const Text('Delete Hospital', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDeleteHospital(existing);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white),
            tooltip: 'Clean Test Hospitals',
            onPressed: _confirmCleanAllTestHospitals,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Hospital', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditHospitalDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Center(
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
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            hosp.address.isNotEmpty
                                                ? '${hosp.district} • ${hosp.address}'
                                                : hosp.district,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            hosp.phone.isNotEmpty ? hosp.phone : 'Not provided',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                tooltip: 'Edit Hospital',
                                onPressed: () => _showAddEditHospitalDialog(hosp),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                                tooltip: 'Delete Hospital',
                                onPressed: () => _confirmDeleteHospital(hosp),
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
                                child: const Text(
                                  'Edit Settings →',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
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
            ),
    );
  }
}
