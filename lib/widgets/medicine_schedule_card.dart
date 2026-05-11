import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MedicineScheduleCard extends StatelessWidget {
  final String medicineName;
  final String dosage;
  final String time;
  final String type; // capsule, tablet, syrup, injection
  final bool isTaken;
  final VoidCallback? onTap;

  const MedicineScheduleCard({
    super.key,
    required this.medicineName,
    required this.dosage,
    required this.time,
    required this.type,
    this.isTaken = false,
    this.onTap,
  });

  IconData get _typeIcon {
    switch (type) {
      case 'capsule':
        return Icons.medication_rounded;
      case 'syrup':
        return Icons.local_drink_rounded;
      case 'injection':
        return Icons.vaccines_rounded;
      default:
        return Icons.medication_liquid_rounded;
    }
  }

  Color get _typeColor {
    switch (type) {
      case 'capsule':
        return AppTheme.capsuleColor;
      case 'syrup':
        return AppTheme.syrupColor;
      case 'injection':
        return AppTheme.injectionColor;
      default:
        return AppTheme.pillColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context).copyWith(
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Row(
        children: [
          // Ikon Obat
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
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
                    const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
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
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Waktu dan Tombol Hapus
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: AppTheme.bodyBold(context).copyWith(
                  fontSize: 16,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 12, color: Colors.red),
                      SizedBox(width: 4),
                      Text("Hapus", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
