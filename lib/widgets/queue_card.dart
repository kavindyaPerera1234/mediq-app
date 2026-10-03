import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/queue_entry.dart';
import 'status_badge.dart';
import 'emergency_badge.dart';

class QueueCard extends StatelessWidget {
  final QueueEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;

  const QueueCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onPrimaryAction,
    this.primaryActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmergency = entry.priority == 'emergency';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEmergency ? AppColors.error : AppColors.border,
          width: isEmergency ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Token Box
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isEmergency ? AppColors.errorLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'TOKEN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.tokenNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isEmergency ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.patientName ?? 'Patient ${entry.tokenNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isEmergency) const EmergencyBadge(compact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Position #${entry.queuePosition} • Est. ~${entry.estimatedWaitMinutes} mins',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: entry.status),
                  ],
                ),
              ),

              // Optional Primary Action Button (e.g. Resume button for on-hold items)
              if (onPrimaryAction != null && primaryActionLabel != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onPrimaryAction,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(60, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    primaryActionLabel!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
