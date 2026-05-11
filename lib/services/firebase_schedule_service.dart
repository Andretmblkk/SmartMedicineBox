import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class FirebaseScheduleService {
  FirebaseScheduleService._privateConstructor();
  static final FirebaseScheduleService instance = FirebaseScheduleService._privateConstructor();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  void startListening() {
    // Listen to changes if needed
  }

  Future<void> saveSchedule(List<Map<String, dynamic>> schedule) async {
    try {
      // Menyimpan data jadwal ke node 'jadwal_obat'
      await _dbRef.child('jadwal_obat').set(schedule);
      debugPrint('Berhasil menyimpan jadwal ke Firebase');
    } catch (e) {
      debugPrint('Gagal menyimpan jadwal ke Firebase: $e');
    }
  }
}
