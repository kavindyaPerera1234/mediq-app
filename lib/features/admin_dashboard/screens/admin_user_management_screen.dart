import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/localization/app_strings.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedRoleFilter = 'all';
  String _searchQuery = '';

  // Hospital & Department presets for staff assignment
  static const List<Map<String, String>> _hospitalOptions = [
    {'id': 'nhsl', 'name': 'National Hospital of Sri Lanka (Colombo)'},
    {'id': 'kandy_gen', 'name': 'Kandy General Hospital'},
    {'id': 'karapitiya', 'name': 'Karapitiya Teaching Hospital'},
    {'id': 'jaffna_th', 'name': 'Teaching Hospital Jaffna'},
  ];

  static const List<Map<String, String>> _departmentOptions = [
    {'id': 'gen_med', 'name': 'General Medicine'},
    {'id': 'pediatrics', 'name': 'Pediatrics'},
    {'id': 'cardiology', 'name': 'Cardiology'},
    {'id': 'ent', 'name': 'Ear, Nose & Throat (ENT)'},
    {'id': 'dermatology', 'name': 'Dermatology'},
    {'id': 'eye', 'name': 'Ophthalmology (Eye Clinic)'},
    {'id': 'dental', 'name': 'Dental & Oral Health'},
  ];

  static const List<String> _availableRoles = [
    'doctor',
    'nurse',
    'receptionist',
    'patient',
    'caregiver',
    'admin',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── TOGGLE ACTIVE / INACTIVE ──────────────────────────────────────────────
  Future<void> _toggleUserActiveStatus(String docId, bool currentStatus) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(docId)
          .update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update staff_profiles if it exists
      try {
        await _firestore
            .collection(AppConstants.staffProfilesCollection)
            .doc(docId)
            .update({
          'isActive': !currentStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus
                ? 'Account activated successfully.'
                : 'Account deactivated. User can no longer sign in.',
          ),
          backgroundColor: !currentStatus ? AppColors.success : AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── CREATE / ADD USER ─────────────────────────────────────────────────────
  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final nicCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final empCtrl = TextEditingController();

    String selectedRole = 'doctor';
    String selectedHospital = _hospitalOptions.first['id']!;
    String selectedDepartment = _departmentOptions.first['id']!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isStaffRole = selectedRole == 'doctor' ||
                selectedRole == 'nurse' ||
                selectedRole == 'receptionist' ||
                selectedRole == 'admin';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add New User',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        TextFormField(
                          controller: nameCtrl,
                          inputFormatters: AppValidators.nameFormatters,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: AppValidators.validateFullName,
                        ),
                        const SizedBox(height: 12),

                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: InputDecoration(
                            labelText: 'System Role *',
                            prefixIcon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _availableRoles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                role[0].toUpperCase() + role.substring(1),
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedRole = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Phone Number (10 digits limit)
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: AppValidators.phoneFormatters,
                          decoration: InputDecoration(
                            labelText: 'Phone Number (10 Digits, e.g. 0771234567) *',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: AppValidators.validatePhone,
                        ),
                        const SizedBox(height: 12),

                        // NIC (12 chars limit)
                        TextFormField(
                          controller: nicCtrl,
                          inputFormatters: AppValidators.nicFormatters,
                          decoration: InputDecoration(
                            labelText: 'National ID / NIC (12 Digits or 9+V) *',
                            prefixIcon: const Icon(Icons.credit_card_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => AppValidators.validateNic(v, required: true),
                        ),
                        const SizedBox(height: 12),

                        // Email
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => AppValidators.validateEmail(v, required: false),
                        ),

                        // If Staff Role, show Hospital, Department & Employee Number
                        if (isStaffRole) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Healthcare Facility Assignment',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Hospital Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedHospital,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Assigned Hospital *',
                              prefixIcon: const Icon(Icons.local_hospital_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _hospitalOptions.map((h) {
                              return DropdownMenuItem(
                                value: h['id'],
                                child: Text(
                                  h['name']!,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedHospital = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Department Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedDepartment,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Assigned Clinic / Department *',
                              prefixIcon: const Icon(Icons.medical_services_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _departmentOptions.map((d) {
                              return DropdownMenuItem(
                                value: d['id'],
                                child: Text(
                                  d['name']!,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedDepartment = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Employee / SLMC License Number
                          TextFormField(
                            controller: empCtrl,
                            decoration: InputDecoration(
                              labelText: 'Staff ID / Employee # (e.g. DOC-104)',
                              prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogCtx);

                    final newDocId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
                    final fullName = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final nic = nicCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final empNo = empCtrl.text.trim().isNotEmpty
                        ? empCtrl.text.trim()
                        : 'EMP-${DateTime.now().millisecondsSinceEpoch % 10000}';

                    final now = FieldValue.serverTimestamp();

                    try {
                      // 1. Write to users collection
                      await _firestore.collection(AppConstants.usersCollection).doc(newDocId).set({
                        'uid': newDocId,
                        'userId': newDocId,
                        'fullName': fullName,
                        'name': fullName,
                        'phoneNumber': phone,
                        'phone': phone,
                        'nic': nic,
                        'email': email,
                        'role': selectedRole,
                        'hospitalId': isStaffRole ? selectedHospital : null,
                        'departmentId': isStaffRole ? selectedDepartment : null,
                        'isActive': true,
                        'createdAt': now,
                        'updatedAt': now,
                      });

                      // 2. If staff role, write to staff_profiles collection
                      if (isStaffRole) {
                        await _firestore
                            .collection(AppConstants.staffProfilesCollection)
                            .doc(newDocId)
                            .set({
                          'userId': newDocId,
                          'staffId': newDocId,
                          'role': selectedRole,
                          'hospitalId': selectedHospital,
                          'departmentId': selectedDepartment,
                          'employeeNumber': empNo,
                          'isActive': true,
                          'createdAt': now,
                          'updatedAt': now,
                        });
                      }

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('User "$fullName" created successfully as $selectedRole.'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create user: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Create User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── EDIT / UPDATE USER ────────────────────────────────────────────────────
  void _showEditUserDialog(String docId, Map<String, dynamic> data) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: data['fullName'] ?? data['name'] ?? '');
    final phoneCtrl = TextEditingController(text: data['phoneNumber'] ?? data['phone'] ?? '');
    final nicCtrl = TextEditingController(text: data['nic'] ?? '');
    final emailCtrl = TextEditingController(text: data['email'] ?? '');
    final empCtrl = TextEditingController(text: data['employeeNumber'] ?? '');

    String selectedRole = (data['role'] ?? 'patient').toString().toLowerCase();
    if (!_availableRoles.contains(selectedRole)) selectedRole = 'patient';

    String selectedHospital = data['hospitalId'] ?? _hospitalOptions.first['id']!;
    if (!_hospitalOptions.any((h) => h['id'] == selectedHospital)) {
      selectedHospital = _hospitalOptions.first['id']!;
    }

    String selectedDepartment = data['departmentId'] ?? _departmentOptions.first['id']!;
    if (!_departmentOptions.any((d) => d['id'] == selectedDepartment)) {
      selectedDepartment = _departmentOptions.first['id']!;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isStaffRole = selectedRole == 'doctor' ||
                selectedRole == 'nurse' ||
                selectedRole == 'receptionist' ||
                selectedRole == 'admin';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit User Profile',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        TextFormField(
                          controller: nameCtrl,
                          inputFormatters: AppValidators.nameFormatters,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: AppValidators.validateFullName,
                        ),
                        const SizedBox(height: 12),

                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: InputDecoration(
                            labelText: 'System Role *',
                            prefixIcon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _availableRoles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                role[0].toUpperCase() + role.substring(1),
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedRole = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Phone Number (10 digits limit)
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: AppValidators.phoneFormatters,
                          decoration: InputDecoration(
                            labelText: 'Phone Number (10 Digits) *',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: AppValidators.validatePhone,
                        ),
                        const SizedBox(height: 12),

                        // NIC (12 chars limit)
                        TextFormField(
                          controller: nicCtrl,
                          inputFormatters: AppValidators.nicFormatters,
                          decoration: InputDecoration(
                            labelText: 'National ID / NIC (12 Digits or 9+V) *',
                            prefixIcon: const Icon(Icons.credit_card_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => AppValidators.validateNic(v, required: true),
                        ),
                        const SizedBox(height: 12),

                        // Email
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => AppValidators.validateEmail(v, required: false),
                        ),

                        // If Staff Role, show Hospital, Department & Employee Number
                        if (isStaffRole) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Healthcare Facility Assignment',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Hospital Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedHospital,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Assigned Hospital',
                              prefixIcon: const Icon(Icons.local_hospital_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _hospitalOptions.map((h) {
                              return DropdownMenuItem(
                                value: h['id'],
                                child: Text(
                                  h['name']!,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedHospital = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Department Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedDepartment,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Assigned Clinic / Department',
                              prefixIcon: const Icon(Icons.medical_services_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _departmentOptions.map((d) {
                              return DropdownMenuItem(
                                value: d['id'],
                                child: Text(
                                  d['name']!,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedDepartment = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Employee / Staff Number
                          TextFormField(
                            controller: empCtrl,
                            decoration: InputDecoration(
                              labelText: 'Staff ID / Employee #',
                              prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogCtx);

                    final fullName = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final nic = nicCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final empNo = empCtrl.text.trim();

                    final now = FieldValue.serverTimestamp();

                    try {
                      // 1. Update users collection
                      await _firestore.collection(AppConstants.usersCollection).doc(docId).update({
                        'fullName': fullName,
                        'name': fullName,
                        'phoneNumber': phone,
                        'phone': phone,
                        'nic': nic,
                        'email': email,
                        'role': selectedRole,
                        'hospitalId': isStaffRole ? selectedHospital : null,
                        'departmentId': isStaffRole ? selectedDepartment : null,
                        'updatedAt': now,
                      });

                      // 2. If staff role, update staff_profiles collection
                      if (isStaffRole) {
                        await _firestore
                            .collection(AppConstants.staffProfilesCollection)
                            .doc(docId)
                            .set({
                          'userId': docId,
                          'staffId': docId,
                          'role': selectedRole,
                          'hospitalId': selectedHospital,
                          'departmentId': selectedDepartment,
                          if (empNo.isNotEmpty) 'employeeNumber': empNo,
                          'updatedAt': now,
                        }, SetOptions(merge: true));
                      }

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('User "$fullName" updated successfully.'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update user: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── DELETE USER ───────────────────────────────────────────────────────────
  void _confirmDeleteUser(String docId, String userName, String userRole) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete User Account',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            'Are you sure you want to permanently delete $userName ($userRole)?\n\n'
            'This action is irreversible and removes the user from the database.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                // Delete from users collection
                await _firestore.collection(AppConstants.usersCollection).doc(docId).delete();

                // Delete from staff_profiles if applicable
                try {
                  await _firestore.collection(AppConstants.staffProfilesCollection).doc(docId).delete();
                } catch (_) {}

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User "$userName" deleted permanently.'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete user: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helper to resolve hospital name
  String _getHospitalName(String? hId) {
    if (hId == null || hId.isEmpty) return '';
    final found = _hospitalOptions.firstWhere((h) => h['id'] == hId, orElse: () => {'name': hId});
    return found['name'] ?? hId;
  }

  // Helper to resolve department name
  String _getDepartmentName(String? dId) {
    if (dId == null || dId.isEmpty) return '';
    final found = _departmentOptions.firstWhere((d) => d['id'] == dId, orElse: () => {'name': dId});
    return found['name'] ?? dId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text(
          S.adminUsersTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add User',
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          'Add User',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        onPressed: _showAddUserDialog,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by Name, Phone, Email, or NIC...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Roles'),
                      const SizedBox(width: 8),
                      _buildFilterChip('patient', 'Patients'),
                      const SizedBox(width: 8),
                      _buildFilterChip('doctor', 'Doctors'),
                      const SizedBox(width: 8),
                      _buildFilterChip('nurse', 'Nurses'),
                      const SizedBox(width: 8),
                      _buildFilterChip('receptionist', 'Receptionists'),
                      const SizedBox(width: 8),
                      _buildFilterChip('caregiver', 'Caregivers'),
                      const SizedBox(width: 8),
                      _buildFilterChip('admin', 'Admins'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // User List Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection(AppConstants.usersCollection).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading users: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data();
                  final name = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
                  final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString().toLowerCase();
                  final nic = (data['nic'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final role = (data['role'] ?? 'patient').toString().toLowerCase();

                  final matchesFilter = _selectedRoleFilter == 'all' || role == _selectedRoleFilter;
                  final matchesSearch = _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      phone.contains(_searchQuery) ||
                      nic.contains(_searchQuery) ||
                      email.contains(_searchQuery);

                  return matchesFilter && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 56,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No users found matching your criteria',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final docId = doc.id;

                    final fullName = data['fullName'] ?? data['name'] ?? 'Unnamed User';
                    final phone = data['phoneNumber'] ?? data['phone'] ?? 'No phone';
                    final nic = data['nic'] ?? 'Not registered';
                    final email = data['email'] ?? '';
                    final role = (data['role'] ?? 'patient').toString().toLowerCase();
                    final isActive = data['isActive'] ?? true;
                    final hospitalId = data['hospitalId'];
                    final departmentId = data['departmentId'];
                    final hospitalName = _getHospitalName(hospitalId);
                    final departmentName = _getDepartmentName(departmentId);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isActive ? AppColors.border : AppColors.error.withValues(alpha: 0.4),
                        ),
                      ),
                      color: isActive ? AppColors.surface : const Color(0xFFFEF2F2),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Role Avatar
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: _getRoleColor(role).withValues(alpha: 0.15),
                                  child: Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 22),
                                ),
                                const SizedBox(width: 12),

                                // User Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              fullName,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(role).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              role.toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: _getRoleColor(role),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '📱 $phone • 🪪 NIC: $nic',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (email.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '✉️ $email',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      if (hospitalName.isNotEmpty || departmentName.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '🏥 $hospitalName ${departmentName.isNotEmpty ? '• 🩺 $departmentName' : ''}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 10),

                            // Action Row: Status Badge + Edit + Activate/Deactivate + Delete
                            Row(
                              children: [
                                // Status Indicator
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive ? AppColors.success : AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'Active' : 'Deactivated',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isActive ? AppColors.success : AppColors.error,
                                  ),
                                ),

                                const Spacer(),

                                // 1. Edit User Button
                                SizedBox(
                                  height: 32,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.edit_outlined, size: 14),
                                    label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    onPressed: () => _showEditUserDialog(docId, data),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // 2. Activate / Deactivate Button
                                SizedBox(
                                  height: 32,
                                  child: OutlinedButton(
                                    onPressed: () => _toggleUserActiveStatus(docId, isActive),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isActive ? AppColors.error : AppColors.success,
                                      side: BorderSide(
                                        color: isActive ? AppColors.error : AppColors.success,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    child: Text(
                                      isActive ? 'Deactivate' : 'Activate',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // 3. Delete Button
                                SizedBox(
                                  height: 32,
                                  width: 36,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                    tooltip: 'Delete User',
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _confirmDeleteUser(docId, fullName, role),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String roleKey, String label) {
    final isSelected = _selectedRoleFilter == roleKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedRoleFilter = roleKey),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Colors.blue;
      case 'nurse':
        return Colors.teal;
      case 'admin':
        return Colors.purple;
      case 'caregiver':
        return Colors.orange;
      case 'receptionist':
        return Colors.indigo;
      case 'patient':
      default:
        return AppColors.primary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Icons.medical_services_rounded;
      case 'nurse':
        return Icons.health_and_safety_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'caregiver':
        return Icons.family_restroom_rounded;
      case 'receptionist':
        return Icons.support_agent_rounded;
      case 'patient':
      default:
        return Icons.person_rounded;
    }
  }
}
