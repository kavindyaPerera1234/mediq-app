import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
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
  final List<Map<String, String>> _demoUsers = [
    {'name': 'Dr. S. Perera', 'email': 'doctor@mediq.lk', 'role': 'doctor', 'dept': 'General Medicine OPD', 'status': 'active'},
    {'name': 'Nurse Fernando', 'email': 'nurse@mediq.lk', 'role': 'nurse', 'dept': 'General Medicine OPD', 'status': 'active'},
    {'name': 'Receptionist Nimali', 'email': 'receptionist@mediq.lk', 'role': 'receptionist', 'dept': 'OPD Desk', 'status': 'active'},
    {'name': 'Nimal Perera', 'email': 'pat-018@patient.mediq.lk', 'role': 'patient', 'dept': 'Patient', 'status': 'active'},
    {'name': 'Nimali Wijesekera', 'email': 'pat-019@patient.mediq.lk', 'role': 'patient', 'dept': 'Patient', 'status': 'active'},
    {'name': 'Suresh Kumar', 'email': 'pat-020@patient.mediq.lk', 'role': 'patient', 'dept': 'Patient', 'status': 'active'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleUserActiveStatus(String docId, bool currentStatus) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(docId)
          .update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
                    hintText: 'Search by Name, Phone, or NIC...',
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
                      _buildFilterChip('caregiver', 'Caregivers'),
                      const SizedBox(width: 8),
                      _buildFilterChip('doctor', 'Doctors'),
                      const SizedBox(width: 8),
                      _buildFilterChip('nurse', 'Nurses'),
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
                  final role = (data['role'] ?? 'patient').toString().toLowerCase();

                  final matchesQuery = _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      phone.contains(_searchQuery) ||
                      nic.contains(_searchQuery);

                  final matchesRole = _selectedRoleFilter == 'all' || role == _selectedRoleFilter;

                  return matchesQuery && matchesRole;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No registered users found.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final docId = doc.id;

                    final fullName = (data['fullName'] ?? data['name'] ?? 'Unnamed User').toString();
                    final phone = (data['phoneNumber'] ?? data['phone'] ?? 'No Phone').toString();
                    final email = (data['email'] ?? '').toString();
                    final nic = (data['nic'] ?? 'No NIC').toString();
                    final role = (data['role'] ?? 'patient').toString().toUpperCase();
                    final isActive = (data['isActive'] is bool) ? (data['isActive'] as bool) : true;

                    return Card(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isActive ? AppColors.border : AppColors.error.withValues(alpha: 0.4),
                        ),
                      ),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Role Avatar
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: _getRoleColor(role).withValues(alpha: 0.15),
                              child: Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 24),
                            ),
                            const SizedBox(width: 14),

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
                                            fontSize: 16,
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
                                          role,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: _getRoleColor(role),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '📱 $phone • 🪪 NIC: $nic',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '✉️ $email',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),

                                  // Active/Inactive Status Badge & Toggle Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
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
                                            isActive ? 'Active Account' : 'Deactivated',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isActive ? AppColors.success : AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Deactivate / Activate Button
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
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                          child: Text(
                                            isActive ? 'Deactivate' : 'Activate',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
