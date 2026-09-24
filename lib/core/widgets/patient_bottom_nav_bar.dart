import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class PatientBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTabSelected;

  const PatientBottomNavBar({
    super.key,
    this.currentIndex = 1, // Default index 1 = "Appointments" (Member 1 active)
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab 0: Home (Dashboard - Shared / Member 3)
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
              ),

              // Tab 1: Appointments (Member 1 - You!)
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Appointments',
              ),

              // Tab 2: Queue (Member 3)
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.format_list_bulleted_outlined,
                activeIcon: Icons.format_list_bulleted,
                label: 'Queue',
              ),

              // Tab 3: Alerts / Notifications (Member 2)
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.notifications_none_outlined,
                activeIcon: Icons.notifications,
                label: 'Alerts',
              ),

              // Tab 4: Profile (Member 3 & Senior Mode)
              _buildNavItem(
                context: context,
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (onTabSelected != null) {
          onTabSelected!(index);
        } else {
          // Default tab tap feedback if no custom callback is set
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Member 3: Live Queue Tracker Module'),
                duration: Duration(milliseconds: 600),
              ),
            );
          } else if (index == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Member 2: Notifications & Alerts Module'),
                duration: Duration(milliseconds: 600),
              ),
            );
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}