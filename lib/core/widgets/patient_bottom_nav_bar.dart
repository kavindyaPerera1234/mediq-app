import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_accessibility.dart';
import '../constants/app_translations.dart';

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
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppAccessibility.isSimplifiedNav,
        AppAccessibility.isHighContrastMode,
        AppAccessibility.currentLanguage,
      ]),
      builder: (context, _) {
        final isSimplified = AppAccessibility.isSimplifiedNav.value;
        final isDark = AppAccessibility.isHighContrastMode.value;

        final navBg = isDark ? const Color(0xFF1C2541) : Colors.white;
        final borderColor = isDark ? const Color(0xFF3A506B) : AppColors.border;

        if (isSimplified) {
          // Senior Simplified 3-Tab Large Navigation
          return Container(
            decoration: BoxDecoration(
              color: navBg,
              border: Border(
                top: BorderSide(color: borderColor, width: 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black45 : Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSimplifiedItem(
                      context: context,
                      index: 0,
                      icon: Icons.home_rounded,
                      label: AppTranslations.tr('navHome'),
                      isSelected: currentIndex == 0,
                      isDark: isDark,
                    ),
                    _buildSimplifiedItem(
                      context: context,
                      index: 1,
                      icon: Icons.calendar_month_rounded,
                      label: AppTranslations.tr('navAppointments'),
                      isSelected: currentIndex == 1,
                      isDark: isDark,
                    ),
                    _buildSimplifiedItem(
                      context: context,
                      index: 4,
                      icon: Icons.person_rounded,
                      label: AppTranslations.tr('navProfile'),
                      isSelected: currentIndex == 4,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Standard 5-Tab Navigation
        return Container(
          decoration: BoxDecoration(
            color: navBg,
            border: Border(
              top: BorderSide(color: borderColor, width: 1),
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
                    label: AppTranslations.tr('navHome'),
                    isDark: isDark,
                  ),

                  // Tab 1: Appointments (Member 1 - You!)
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today,
                    label: AppTranslations.tr('navAppointments'),
                    isDark: isDark,
                  ),

                  // Tab 2: Queue (Member 3)
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: Icons.format_list_bulleted_outlined,
                    activeIcon: Icons.format_list_bulleted,
                    label: AppTranslations.tr('navQueue'),
                    isDark: isDark,
                  ),

                  // Tab 3: Alerts / Notifications (Member 2)
                  _buildNavItem(
                    context: context,
                    index: 3,
                    icon: Icons.notifications_none_outlined,
                    activeIcon: Icons.notifications,
                    label: AppTranslations.tr('navAlerts'),
                    isDark: isDark,
                  ),

                  // Tab 4: Profile (Member 3 & Senior Mode)
                  _buildNavItem(
                    context: context,
                    index: 4,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: AppTranslations.tr('navProfile'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimplifiedItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeColor = isDark ? const Color(0xFF38BDF8) : AppColors.primary;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
    final activeBg = isDark ? const Color(0xFF243356) : AppColors.primaryLight;

    return GestureDetector(
      onTap: () {
        if (onTabSelected != null) {
          onTabSelected!(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: activeColor, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
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
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = isDark ? const Color(0xFF38BDF8) : AppColors.primary;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

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
            color: isSelected ? activeColor : inactiveColor,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}