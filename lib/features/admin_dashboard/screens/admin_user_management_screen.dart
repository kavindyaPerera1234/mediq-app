import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/seed_data_service.dart';
import '../../../widgets/status_badge.dart';

class AdminUserManagementScreen extends StatefulWidget {
  final AuthService authService;

  const AdminUserManagementScreen({
    super.key,
    required this.authService,
  });

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final SeedDataService _seedDataService = SeedDataService();
  bool _isSeeding = false;

  final List<Map<String, String>> _demoUsers = [
    {'name': 'Dr. Silva', 'email': 'doctor@mediq.lk', 'role': 'doctor', 'dept': 'General Medicine OPD', 'status': 'active'},
    {'name': 'Nurse Fernando', 'email': 'nurse@mediq.lk', 'role': 'nurse', 'dept': 'General Medicine OPD', 'status': 'active'},
    {'name': 'Receptionist Silva', 'email': 'receptionist@mediq.lk', 'role': 'receptionist', 'dept': 'OPD Desk', 'status': 'active'},
    {'name': 'Nimal Perera', 'email': 'pat-018@patient.mediq.lk', 'role': 'patient', 'dept': 'Patient', 'status': 'active'},
    {'name': 'Nimali Wijesekera', 'email': 'pat-019@patient.mediq.lk', 'role': 'patient', 'dept': 'Patient', 'status': 'active'},
    {'name': 'Suresh Kumar', 'email': 'pat-020@patient.mediq.lk', 'role': 'patient', 'dept': 'Patient', 'status': 'active'},
  ];

  Future<void> _handleReSeed() async {
    setState(() => _isSeeding = true);
    final success = await _seedDataService.seedDemoData();
    setState(() => _isSeeding = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User Registry & Shared Collections Re-seeded!' : 'Seeding failed.'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Registry & Role Management'),
        actions: [
          IconButton(
            icon: _isSeeding ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_sync_rounded),
            tooltip: 'Re-seed Shared Users',
            onPressed: _isSeeding ? null : _handleReSeed,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'REGISTERED SYSTEM USERS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _demoUsers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final u = _demoUsers[index];
                  final isStaff = u['role'] != 'patient';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isStaff ? AppColors.primaryLight : AppColors.infoLight,
                        child: Icon(
                          isStaff ? Icons.badge_rounded : Icons.person_rounded,
                          color: isStaff ? AppColors.primary : AppColors.info,
                        ),
                      ),
                      title: Text(u['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${u['role']!.toUpperCase()} • ${u['email']}'),
                      trailing: StatusBadge(status: u['status']!),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
