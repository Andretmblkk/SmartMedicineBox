# Panduan Pemecahan Masalah (Troubleshooting)

Dokumen ini mendeskripsikan kendala umum yang paling sering terjadi selama proses kompilasi (*build*) maupun saat eksekusi (*runtime*) aplikasi Smart Medicine Tracker, beserta cara mengatasinya.

---

## Masalah 1: Firebase Gagal Menginisialisasi (No Firebase Options)
**Gejala:** Aplikasi memunculkan *blank/red screen* atau *crash* dengan *Error log* di konsol:
`[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()`
**Penyebab:**
File `firebase_options.dart` tidak ditemukan atau belum diregenerasi sesuai akun sistem Anda.
**Solusi:**
1. Buka terminal proyek Anda.
2. Ketik dan jalankan perintah: `flutterfire configure`.
3. Pilih kembali project Anda, lalu otomatis FlutterFire akan men-generate ulang file integrasi spesifik untuk sistem dan nama paket (bundle id) aplikasi Anda.

---

## Masalah 2: Notifikasi/Alarm Tidak Muncul di Waktu yang Ditentukan
**Gejala:** Jadwal sudah diset "08:00", namun HP diam saja.
**Penyebab:** 
Ada dua kemungkinan: Android OS memblokir akses *Exact Alarm* (mulai Android 12+), atau *Timezone* (zona waktu ponsel) tidak sesuai dengan UTC yang dikonfigurasi.
**Solusi:**
1. Pastikan Anda telah memberikan Izin Notifikasi (Allow Notifications) saat aplikasi pertama kali dibuka.
2. Untuk izin ekstra, buka *Pengaturan HP (Settings) -> Aplikasi -> Smart Medicine Tracker -> Alarms & Reminders -> Aktifkan "Allow setting alarms and reminders"*.
3. Periksa kembali script `_initServices()` di `main.dart` untuk memastikan baris `await NotificationService.instance.init();` tidak di-*comment* atau tertahan oleh error sebelumnya.

---

## Masalah 3: Modul IoT (ESP32 V3) Tidak Bereaksi pada Kotak Obat
**Gejala:** Anda menghapus atau menambah jadwal obat di aplikasi, aplikasi berhasil memperbarui tampilan, tetapi motor Servo di modul IoT fisik diam tidak merespon.
**Penyebab:**
Aplikasi tidak berhasil mendorong (push) JSON ke node Firebase Realtime Database.
**Solusi:**
1. Buka Firebase Console -> Realtime Database. Perhatikan node `jadwal_obat`.
2. Klik tombol hapus/tambah di UI Aplikasi Flutter, amati Firebase Console (biasanya bagian node akan berkedip kuning dan hijau). Jika tidak berkedip, pastikan HP Anda tersambung ke jaringan internet dengan baik.
3. Cek Tab "Rules" (Aturan) di Realtime Database. Pastikan terbaca `".read": true, ".write": true`. Jika diset false (mode produksi), aplikasi Flutter Anda tertolak/Access Denied.
4. Cek file `firebase_options.dart` dan cocokkan *Database URL* dengan nama *Instance* di Firebase.
5. Jika masalah ada di modul IoT, cek sintaks C++ `ArduinoJson`, mungkin kunci pencarian (Key JSON) seperti "time" (Waktu) tidak cocok (*Case-sensitive*).

---

## Masalah 4: Kesalahan Resolusi Depedency AndroidX
**Gejala:** Saat perintah `flutter run`, kompilasi gagal pada modul Gradle/Java.
`Exception in thread "main" java.lang.RuntimeException: Duplicate class ...`
**Penyebab:**
Bentrokan modul *flutter_local_notifications* dan *firebase_core* di mana keduanya mungkin meminta versi AndroidX yang berbeda, atau *Multidex* belum diaktifkan.
**Solusi:**
1. Hapus folder sampah dengan `flutter clean`.
2. Jalankan `flutter pub get`.
3. Masuk ke folder `android/` di terminal, lalu paksa bersihkan Gradle via `gradlew clean` (atau `./gradlew clean` pada Mac).
4. Build kembali.

---

## Masalah 5: Error Path `flutterfire` Tidak Dikenali di Windows
**Gejala:** Menjalankan perintah `flutterfire configure` menghasilkan pesan `"flutterfire is not recognized as an internal or external command"`.
**Penyebab:**
Sistem operasi belum meregistrasi folder lokal instalasi pub (alat manajemen paket bahasa Dart) ke dalam variabel environment PATH OS.
**Solusi:**
Solusi instan tanpa membongkar konfigurasi Path adalah dengan mengeksekusinya via instruksi *Run* eksekusi global:
```bash
dart pub global run flutterfire_cli:flutterfire configure
```

