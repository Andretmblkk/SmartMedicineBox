# Panduan Instalasi (Setup Guide)

Dokumen ini berisi instruksi teknis untuk menyiapkan lingkungan kerja *(Development Environment)* aplikasi Smart Medicine Tracker di PC/Laptop Anda dari nol (from scratch).

---

## 1. Persyaratan Sistem (Prerequisites)

Pastikan sistem Anda sudah terinstal perangkat lunak berikut:
1. **Flutter SDK** (versi 3.11.5 atau lebih baru yang mendukung *Dart 3*).
2. **Android Studio** atau **VS Code** (beserta ekstensi/plugin Flutter & Dart).
3. **Android SDK** dengan *Platform-tools* dan *Build-tools* (biasanya disertakan dalam Android Studio). Disarankan menggunakan API Level 34.
4. **Git** untuk *Version Control System*.
5. **Node.js & npm** (digunakan untuk menginstal tools Firebase).

---

## 2. Proses Cloning & Download Package

1. Buka Terminal atau Command Prompt, lalu arahkan ke direktori pilihan Anda.
2. Clone repositori aplikasi:
   ```bash
   git clone <url-repository>
   ```
3. Masuk ke folder proyek:
   ```bash
   cd medicinetreatment
   ```
4. Unduh dan perbarui seluruh modul Flutter (`pubspec.yaml`):
   ```bash
   flutter pub get
   ```

---

## 3. Menghubungkan Firebase (Wajib)

Karena fitur notifikasi terikat dengan sinkronisasi ke kotak alat IoT (lewat Firebase), aplikasi akan ***Crash* / Gagal** terbuka jika Anda melewati langkah ini tanpa mengkonfigurasi ulang API Key yang valid.

### Langkah-langkah FlutterFire CLI:
1. Instal CLI resmi dari Firebase melalui Node.js:
   ```bash
   npm install -g firebase-tools
   ```
2. Lakukan login otentikasi Google:
   ```bash
   firebase login
   ```
3. Aktifkan modul pembantu `flutterfire` di mesin lokal Anda:
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. *(Jika Windows, pastikan direktori cache `pub global` sudah masuk dalam `PATH` Environment Variables Anda).*
5. Konfigurasi ulang Firebase langsung ke dalam proyek ini:
   ```bash
   flutterfire configure
   ```
   *   Pilih project ID Anda (misal: `smart-medicine-box-c4058`).
   *   Pilih platform target (Cukup centang `android` dan `ios`).
6. Perintah ini akan menghasilkan / meregenerasi file **`lib/firebase_options.dart`**.

---

## 4. Persetujuan OS dan Izin (Android Permissions)

Aplikasi pengingat medis memerlukan izin OS yang kuat untuk menjebol sistem mode tidur (*Doze Mode*) dari OS Android untuk membangunkan notifikasi tepat waktu.

Izin berikut telah ditulis dalam `android/app/src/main/AndroidManifest.xml`:
*   `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>` (Untuk mengembalikan alarm jika HP baru dinyalakan ulang).
*   `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>` (Penting di Android 12+, tanpa ini fungsi notifikasi akan gagal total (error / exception)).
*   `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` (Penting di Android 13+ untuk menampilkan wujud notifikasinya).

Jika Anda mengalami error ketika mengompilasi, pastikan `compileSdkVersion` di `android/app/build.gradle` setidaknya berada di versi **34**.

---

## 5. Menjalankan Aplikasi

Jika Anda sudah menyiapkan Emulator (AVD) atau menghubungkan HP Fisik via kabel USB (Developer Mode & USB Debugging AKTIF):

```bash
flutter run
```

*Tip:* Untuk menjalankan proses dengan performa asli tanpa hambatan debugger, gunakan perintah `flutter run --release`.
