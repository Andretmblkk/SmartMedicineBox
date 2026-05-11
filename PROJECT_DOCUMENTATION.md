# Project Documentation: Smart Medicine Tracker

Dokumen ini merupakan penjelasan pusat (Overview) teknis mengenai keseluruhan proyek Smart Medicine Tracker, dirancang untuk memudahkan developer baru (onboarding) dalam memahami struktur, alur, dan utang teknis (technical debt) dari proyek ini.

---

## 1. Gambaran Umum Project

*   **Fungsi Aplikasi:** Smart Medicine Tracker adalah aplikasi mobile berbasis Flutter yang mencatat rutinitas minum obat pengguna. Aplikasi ini mengandalkan alarm *on-device* yang akurat dan sinkronisasi cloud yang memungkinkan perangkat perangkat keras terintegrasi ikut bereaksi (misalnya membuka kotak obat).
*   **Tujuan Sistem:** Menjembatani celah antara perangkat lunak (pengingat digital) dan perangkat keras fisik (dispenser obat mekanis IoT). Sistem ini mengeliminasi *human error* dari pasien yang kelupaan.
*   **Cara Kerja Aplikasi:**
    1. Pengguna mendaftarkan namanya (disimpan di SharedPreferences).
    2. Pengguna menambah jadwal obat baru (nama, dosis, waktu, aturan pakai).
    3. Aplikasi menjadwalkan notifikasi lokal di OS (Android/iOS) pada jam yang ditentukan.
    4. Secara paralel, aplikasi meng-encode list jadwal tersebut menjadi JSON dan mengunggahnya ke Firebase Realtime Database.
    5. Sensor/Microcontroller (ESP8266/ESP32) membaca database tersebut setiap saat dan menggerakkan servo ketika waktu di alat cocok dengan jadwal di Firebase.

---

## 2. Arsitektur Project

*   **Pola Arsitektur:** Proyek ini menggunakan pola arsitektur **Feature-first MVC Sederhana**. Tidak ada arsitektur ketat seperti *Clean Architecture*. UI dan State bergabung dalam satu layar menggunakan pola Stateful Widget.
*   **Layer Project:**
    *   **UI Layer:** Berada di dalam folder `screens` dan `widgets`.
    *   **Service / Data Layer:** Berada di dalam folder `services` (`FirebaseScheduleService`, `NotificationService`).
    *   **Persistence Layer:** Ditangani oleh *SharedPreferences* langsung di dalam class UI (Tightly coupled).
*   **Dependency Structure:**
    *   `UI` memanggil `Services` (Satu Arah).
    *   Tidak ada *Dependency Injection* framework (GetIt / Injectable). Class Service dipanggil menggunakan pola **Singleton** (contoh: `NotificationService.instance`).

---

## 3. App Lifecycle

1.  **Startup App (`main.dart`):** Aplikasi dijalankan, `WidgetsFlutterBinding.ensureInitialized()` dipanggil.
2.  **Initialization:** Sistem tema (System UI Overlay) diatur, lalu `_initServices()` dijalankan secara *asynchronous* di background agar UI tidak memblokir (stuck di logo).
3.  **Firebase & Notification Check:**
    *   Notifikasi meminta *Permissions* (khususnya untuk Android 13+).
    *   Firebase memanggil `Firebase.initializeApp()`.
4.  **Routing Awal:** Aplikasi langsung me-load `BerandaScreen`.
5.  **Session Check:** Pada `initState` di `BerandaScreen`, aplikasi mengecek `SharedPreferences`. Jika nama pengguna kosong, pop-up dialog "Selamat Datang" muncul untuk meminta input nama pengguna.

---

## 4. Struktur Folder

Berikut adalah anatomi folder utama di dalam direktori `lib/`:

*   **`screens/`**
    *   **Fungsi:** Menyimpan halaman-halaman utama (Full screen route).
    *   **Isi Penting:** `beranda_screen.dart` (Dashboard utama), `tambah_jadwal_screen.dart` (Form input jadwal).
    *   **Hubungan:** Dipanggil oleh `main.dart` dan saling memanggil via `Navigator.push`.
*   **`widgets/`**
    *   **Fungsi:** Menyimpan potongan UI yang dapat digunakan ulang (Reusable Components).
    *   **Isi Penting:** `medicine_schedule_card.dart` (Kartu obat), `quick_stat_card.dart`, `adherence_ring.dart` (Progress bar radial).
    *   **Hubungan:** Secara konstan diimpor oleh file-file di dalam `screens/`.
*   **`services/`**
    *   **Fungsi:** Menangani logika bisnis yang berhubungan dengan eksternal API/OS.
    *   **Isi Penting:** `firebase_schedule_service.dart` (Komunikasi ke Realtime Database), `notification_service.dart` (Pembuatan alarm dan penanganan zona waktu lokal).
    *   **Hubungan:** Dipanggil oleh `screens/` ketika aksi simpan atau hapus data dipicu.
*   **`theme/`**
    *   **Fungsi:** Pusat konfigurasi gaya UI.
    *   **Isi Penting:** `app_theme.dart` (Warna, Font, Dekorasi), `theme_provider.dart` (Manajemen transisi dark/light mode).
    *   **Hubungan:** Diimpor hampir di semua file UI.

*(Catatan: Proyek ini belum menggunakan folder `models`, `bloc`, `controllers`, atau `routes` terpisah. Model data direpresentasikan menggunakan `List<Map<String, dynamic>>`.)*

---

## 5. Dependency Antar Module

Alur pemanggilan (Flow):
1.  **`main.dart`** -> Memuat `BerandaScreen` & inisialisasi `NotificationService`, `FirebaseScheduleService`.
2.  **`BerandaScreen`** -> Memuat `SharedPreferences` (Data cache), merender `MedicineScheduleCard`.
3.  **`BerandaScreen`** -> Membuka `TambahJadwalScreen` (melalui Floating Action Button / Menu).
4.  **`TambahJadwalScreen`** -> Memanggil `NotificationService` untuk membuat jadwal alarm OS.
5.  **`TambahJadwalScreen`** -> Mengembalikan data (`Navigator.pop(data)`).
6.  **`BerandaScreen`** -> Menerima data, menyimpannya ke `SharedPreferences`, lalu menembakkan fungsi `FirebaseScheduleService.instance.saveSchedule(data)` untuk sinkronisasi IoT.

---

## 6. File Penting

| File | Fungsi | Penting Untuk |
| :--- | :--- | :--- |
| `main.dart` | Entry point, Theme injection, Init Firebase & Notifikasi | Proses bootstrapping aplikasi. Jika rusak, app *crash* saat dibuka. |
| `beranda_screen.dart` | Menampilkan dashboard dan merangkum logika manajemen *state* jadwal | Menangani *Local Caching* dan pemicu sinkronisasi Firebase. |
| `tambah_jadwal_screen.dart`| Form input pengguna, konfigurasi alarm notifikasi | Menentukan struktur JSON objek jadwal obat yang valid. |
| `notification_service.dart`| Pengaturan zona waktu, Izin OS, dan Penjadwalan *Exact Alarm* | Inti dari sistem pengingat pasien. |
| `firebase_schedule_service.dart`| *Push* JSON jadwal ke Node *jadwal_obat* | Penghubung nyawa aplikasi ke hardware IoT (ESP8266). |

---

## 7. Critical Files

**⚠️ JANGAN UBAH SEMBARANGAN:**
*   **`lib/services/notification_service.dart`**: File ini menangani `tz.initializeTimeZones()` dan `AndroidNotificationDetails`. Mengubah format waktu secara sembarangan bisa menyebabkan offset waktu (alarm menyala di jam yang salah atau error pada Android 12+ terkait *Exact Alarm Permission*).
*   **`firebase_options.dart`**: Otomatis di-_generate_ oleh Google. Merubah String hash di sini dapat memutuskan koneksi Realtime Database.

---

## 8. Technical Debt

*   **Pola Desain Tightly-Coupled:** `SharedPreferences` dan manipulasi List secara langsung di dalam `_BerandaScreenState` membuat aplikasi sulit di-*Unit Testing*. 
    *   *Saran Optimasi:* Pindahkan struktur *List* obat ini menjadi Class Controller khusus atau menggunakan Provider.
*   **Keamanan Tipe Data (Type Safety):** Penggunaan `List<Map<String, dynamic>>` sangat rawan *typo*. 
    *   *Saran Optimasi:* Buat file `medicine_model.dart` yang mengimplementasikan metode `fromJson()` dan `toJson()`.
*   **Manajemen Pembatalan (Cancellation):** Pada versi ini, saat pengguna menghapus jadwal obat di `BerandaScreen` (`_removeMedicine`), alarm notifikasi tidak otomatis dihapus dari *Flutter Local Notifications*. ID notifikasinya di-generate secara *random* (`math.Random().nextInt(100000)`), sehingga ID tidak tersimpan untuk dihapus nanti.
    *   *Isu Potensial:* Pasien akan tetap menerima notifikasi dari jadwal yang sudah dihapus.
*   **Duplikasi Pemanggilan Firebase:** Setiap ada penambahan atau penghapusan jadwal, aplikasi me-replace seluruh array JSON ke Firebase (tidak meng-_update_ node spesifik), sehingga bisa kurang efisien dari sisi *bandwidth* jaringan jika daftar obat sangat banyak.
