import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../features/auth_live_queue_module3/screens/auth/welcome_entry_screen.dart';
import '../features/auth_live_queue_module3/services/auth_service.dart' as m3_auth;

class StaffBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const StaffBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.format_list_bulleted_rounded),
          label: 'Queue',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_alt_rounded),
          label: 'Patients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_rounded),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }

  static void showStaffProfileModal(BuildContext context, AuthService authService) {
    final user = authService.currentUserModel;
    final profile = authService.currentStaffProfile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.person_rounded, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                user?.fullName ?? 'Dr. Silva',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${(profile?.role ?? user?.role ?? 'Doctor').toUpperCase()} • General Medicine OPD',
                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
                title: const Text('Staff ID'),
                trailing: Text(profile?.staffId ?? 'DOC-001', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                title: const Text('Hospital'),
                trailing: const Text('Colombo General', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
                title: const Text('Account Status'),
                trailing: const Text('Active', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmStaffLogout(context, authService),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log Out of Staff Portal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Dismiss', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static void _confirmStaffLogout(BuildContext sheetContext, AuthService authService) {
    showDialog(
      context: sheetContext,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Log Out'),
            ],
          ),
          content: const Text(
            'Are you sure you want to end your clinical staff session and return to the main portal?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx); // close dialog
                Navigator.pop(sheetContext); // close bottom sheet
                await authService.signOut();
                await m3_auth.AuthService().logout();
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeEntryScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
