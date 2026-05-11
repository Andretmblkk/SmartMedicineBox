# Firebase Realtime Database Integration

Dokumen ini menjelaskan implementasi Firebase di dalam aplikasi Smart Medicine Tracker dan fungsinya sebagai penghubung (jembatan data) untuk perangkat keras IoT (ESP32 V3).

---

## 1. Peran Firebase dalam Proyek Ini

Firebase dalam proyek Smart Medicine Tracker tidak digunakan sebagai database relational utama, melainkan berfungsi sebagai **Message Broker / Realtime Sink** untuk sistem IoT. 

Ketika pengguna mengatur jadwal di aplikasi *mobile*, kotak obat di dunia nyata tidak bisa "melihat" jadwal tersebut secara langsung karena tidak terhubung langsung ke HP. Firebase Realtime Database menyelesaikan masalah ini dengan menyediakan *Node* JSON yang tersimpan di cloud, di mana:
*   **Flutter App:** Bertindak sebagai *Publisher* (Menulis data jadwal).
*   **Hardware (ESP32 V3):** Bertindak sebagai *Subscriber* (Membaca data jadwal setiap saat via koneksi Wi-Fi).

---

## 2. Inisialisasi Firebase

Inisialisasi dilakukan pada proses awal menjalankan aplikasi di file `lib/main.dart`:

```dart
// Di dalam fungsi main()
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```
Konfigurasi `DefaultFirebaseOptions` merujuk pada file `lib/firebase_options.dart` yang dihasilkan otomatis oleh *FlutterFire CLI*. File tersebut berisi kredensial aman dari proyek `smart-medicine-box-c4058`.

---

## 3. Komunikasi dengan Realtime Database

Fungsi komunikasi dienkapsulasi (dibungkus) di dalam file `lib/services/firebase_schedule_service.dart`.

### A. Pola *Singleton*
Class `FirebaseScheduleService` diimplementasikan dengan pola Singleton (hanya ada 1 *instance* yang aktif selama aplikasi berjalan) untuk menghemat pemakaian memori dan menghindari koneksi database ganda.
```dart
class FirebaseScheduleService {
  static final FirebaseScheduleService instance = FirebaseScheduleService._init();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  // ...
}
```

### B. Node Database
Data jadwal selalu ditulis ke direktori (node) dengan path `jadwal_obat`.
```dart
Future<void> saveSchedule(List<dynamic> schedules) async {
  try {
    // Menimpa node 'jadwal_obat' dengan data List terbaru
    await _dbRef.child('jadwal_obat').set(schedules);
    print("Data jadwal berhasil disimpan ke Firebase.");
  } catch (e) {
    print("Error menyimpan jadwal ke Firebase: $e");
  }
}
```

---

## 4. Pola Sinkronisasi Data

Setiap ada perubahan pada jadwal (seperti penambahan jadwal baru atau penghapusan jadwal lama), fungsi `_saveSchedule` di dalam `BerandaScreen` akan dipanggil. Fungsi ini akan:
1. Menyimpan data berbentuk String (`jsonEncode`) ke penyimpanan lokal *SharedPreferences*.
2. Memanggil `FirebaseScheduleService.instance.saveSchedule` untuk mengirim List mentah yang sama ke Firebase.

Ini adalah bentuk penyelarasan dua arah secara *blind push* (Aplikasi selalu menimpa seluruh node Firebase dengan versi terbaru yang ada di HP, bukan melakukan `update` parsial).

---

## 5. Keamanan & Konfigurasi Firebase (*Rules*)

Saat ini (dalam tahap *prototyping*), Firebase Realtime Database di atur ke dalam mode publik (**Test Mode**). Aturan ini sengaja diset terbuka agar modul ESP32 V3 dapat melakukan pembacaan (*GET request* HTTP atau Firebase Library di Arduino IDE) tanpa harus mengimplementasikan algoritma Autentikasi yang rumit di C++.

**Aturan Firebase saat ini:**
```json
{
  "rules": {
    ".read": "true",
    ".write": "true"
  }
}
```

**âš ï¸ Peringatan untuk Rilis Produksi:**
Jika aplikasi ini sudah melewati tahap tugas/prototipe dan siap disebar ke publik secara nyata, aturan di atas sangat berbahaya karena siapa saja bisa menghapus atau mengubah jadwal obat orang lain jika mengetahui URL Firebase-nya. Untuk produksi, perlu diimplementasikan *Firebase Authentication* (Anonymous Login) di Flutter dan IoT, lalu aturan diubah menjadi `".read": "auth != null"`.

