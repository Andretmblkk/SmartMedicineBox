import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MedicineScheduleCard extends StatelessWidget {
  final String medicineName;
  final String dosage;
  final String time;
  final String type; // tablet, capsule
  final int medicineBox;
  final int remainingStock;

  const MedicineScheduleCard({
    super.key,
    required this.medicineName,
    required this.dosage,
    required this.time,
    required this.type,
    required this.medicineBox,
    required this.remainingStock,
  });

  IconData get _typeIcon {
    switch (type) {
      case 'capsule':
        return Icons.medication_rounded;
      default:
        return Icons.medication_liquid_rounded;
    }
  }

  Color get _typeColor {
    switch (type) {
      case 'capsule':
        return AppTheme.capsuleColor;
      default:
        return AppTheme.pillColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLowStock = remainingStock <= 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(
        context,
      ).copyWith(border: Border.all(color: Colors.grey[100]!, width: 1)),
      child: Row(
        children: [
          // Ikon Obat
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 24),
          ),
          const SizedBox(width: 16),
          // Informasi Obat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: AppTheme.bodyBold(context).copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dosage,
                        style: AppTheme.caption(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kotak Obat: $medicineBox',
                      style: AppTheme.caption(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isLowStock
                          ? Icons.warning_amber_rounded
                          : Icons.inventory_2_outlined,
                      size: 14,
                      color: isLowStock ? AppTheme.warning : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sisa Obat: $remainingStock',
                      style: AppTheme.caption(context).copyWith(
                        color: isLowStock
                            ? AppTheme.warning
                            : AppTheme.textSecondary(context),
                        fontWeight: isLowStock
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: AppTheme.bodyBold(
                  context,
                ).copyWith(fontSize: 16, color: AppTheme.primaryBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
