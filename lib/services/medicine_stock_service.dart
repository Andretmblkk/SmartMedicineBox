import '../models/medicine_schedule.dart';
import 'notification_service.dart';

class MedicineStockService {
  MedicineStockService._privateConstructor();
  static final MedicineStockService instance =
      MedicineStockService._privateConstructor();

  Future<List<MedicineSchedule>> reduceStock({
    required List<MedicineSchedule> schedules,
    required MedicineSchedule selectedSchedule,
    String? stockUpdateDate,
  }) async {
    final sharedStock = schedules
        .where((schedule) => schedule.isSameMedicine(selectedSchedule))
        .map((schedule) => schedule.remainingStock)
        .fold<int?>(
          null,
          (lowestStock, stock) =>
              lowestStock == null || stock < lowestStock ? stock : lowestStock,
        );
    final newStock = (sharedStock ?? selectedSchedule.remainingStock) -
        selectedSchedule.dose;

    if (newStock <= 0) {
      await cancelNotifications(schedules, selectedSchedule);
      return removeMedicineSchedules(schedules, selectedSchedule);
    }

    return schedules.map((schedule) {
      if (!schedule.isSameMedicine(selectedSchedule)) return schedule;

      return schedule.copyWith(remainingStock: newStock);
    }).map((schedule) {
      if (schedule.id != selectedSchedule.id || stockUpdateDate == null) {
        return schedule;
      }

      return schedule.copyWith(lastStockUpdateDate: stockUpdateDate);
    }).toList();
  }

  List<MedicineSchedule> removeMedicineSchedules(
    List<MedicineSchedule> schedules,
    MedicineSchedule selectedSchedule,
  ) {
    return schedules
        .where((schedule) => !schedule.isSameMedicine(selectedSchedule))
        .toList();
  }

  List<Map<String, dynamic>> updateSchedules(List<MedicineSchedule> schedules) {
    return schedules.map((schedule) => schedule.toJson()).toList();
  }

  Future<void> cancelNotifications(
    List<MedicineSchedule> schedules,
    MedicineSchedule selectedSchedule,
  ) async {
    final relatedSchedules = schedules.where(
      (schedule) => schedule.isSameMedicine(selectedSchedule),
    );

    for (final schedule in relatedSchedules) {
      await NotificationService.instance.cancel(schedule.notificationId);
    }
  }
}
