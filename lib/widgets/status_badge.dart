import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isLarge;

  const StatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'waiting':
        bg = AppColors.infoLight;
        fg = AppColors.info;
        label = 'WAITING';
        break;
      case 'approaching':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = 'APPROACHING';
        break;
      case 'called':
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = 'CALLED';
        break;
      case 'in_consultation':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        label = 'IN CONSULTATION';
        break;
      case 'on_hold':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = 'ON HOLD';
        break;
      case 'missed':
      case 'skipped':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = 'SKIPPED';
        break;
      case 'rejoined':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        label = 'REJOINED';
        break;
      case 'completed':
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = 'COMPLETED';
        break;
      case 'active':
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = 'ACTIVE';
        break;
      case 'paused':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = 'PAUSED';
        break;
      case 'delayed':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = 'DELAYED';
        break;
      default:
        bg = AppColors.neutralLight;
        fg = AppColors.neutral;
        label = status.toUpperCase().replaceAll('_', ' ');
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isLarge ? 13 : 11,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
