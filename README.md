# Smart Medicine Tracker

![Smart Medicine Tracker](assets/images/logo.png) <!-- Ganti dengan path logo asli jika ada -->

Sebuah aplikasi pengingat jadwal minum obat cerdas yang terintegrasi langsung dengan perangkat keras (IoT) via Firebase. Aplikasi ini dirancang untuk memastikan pengguna tidak pernah melewatkan jadwal obat mereka berkat sistem notifikasi lokal yang akurat dan kemampuan mengontrol servo kotak obat secara real-time.

---

## ðŸ“Œ Project Overview

*   **Nama Aplikasi:** Smart Medicine Tracker
*   **Fungsi Aplikasi:** Mengelola jadwal minum obat, memberikan notifikasi pengingat secara lokal di perangkat, dan mensinkronisasikan jadwal tersebut ke perangkat IoT (ESP32 V3) untuk menggerakkan kotak obat mekanis.
*   **Tujuan Aplikasi:** Membantu pasien atau orang tua yang sering lupa jadwal minum obat, memastikan dosis dan waktu yang tepat, serta mengotomatisasi penyajian obat secara fisik.
*   **Fitur Utama:**
    *   Sistem Penjadwalan Multi-waktu (Pagi, Siang, Malam).
    *   Notifikasi Alarm Lokal (berbasis Timezone dan Exact Alarms).
    *   Sinkronisasi Cloud secara Real-time (ke Firebase).
    *   Penyimpanan Lokal (Offline Support via SharedPreferences).
    *   Antarmuka pengguna (UI) modern berbasis kartu (Card-based).
*   **User Target:** Pasien rawat jalan, lansia, atau pendamping pasien yang memerlukan bantuan ekstra dalam manajemen pengobatan rutin.

---

## ðŸ› ï¸ Tech Stack

*   **Flutter Version:** ^3.11.5 (Sesuai constraint SDK)
*   **Dart Version:** Mendukung Dart 3
*   **Architecture Pattern:** UI-Driven MVC Sederhana (StatefulWidget)
*   **State Management:** `setState` (Native Flutter) dipadukan dengan SharedPreferences untuk persistensi lokal.
*   **Local Database / Cache:** `shared_preferences: ^2.5.5`
*   **Notification System:** `flutter_local_notifications: ^19.2.1` & `flutter_timezone: ^5.0.2`
*   **Firebase Services:**
    *   `firebase_core: ^3.13.0` (Inisialisasi)
    *   `firebase_database: ^11.3.4` (Realtime Database untuk koneksi IoT)
*   **UI / UX Tools:**
    *   `google_fonts: ^6.1.0` (Tipografi modern)
    *   `cupertino_icons: ^1.0.8`
    *   `lottie: ^3.3.1` (Animasi vector)

---

## âš™ï¸ Installation

Berikut adalah langkah-langkah lengkap untuk memasang dan menjalankan proyek ini di lingkungan lokal Anda.

### 1. Clone Repository
Buka terminal dan clone repository ini:
```bash
git clone <url-repository>
cd medicinetreatment
```

### 2. Install Dependency
Unduh semua package yang diperlukan:
```bash
flutter pub get
```

### 3. Setup Firebase
Karena proyek ini terhubung ke Firebase, Anda harus melakukan konfigurasi ulang untuk akun Anda:
1. Pastikan Anda telah menginstal Firebase CLI (`npm install -g firebase-tools`).
2. Login ke akun Firebase (`firebase login`).
3. Aktifkan FlutterFire CLI (`dart pub global activate flutterfire_cli`).
4. Jalankan perintah konfigurasi:
   ```bash
   flutterfire configure
   ```
5. Pilih project Firebase Anda. File `lib/firebase_options.dart` akan otomatis terbuat.

### 4. Setup Realtime Database
1. Buka Firebase Console.
2. Masuk ke **Realtime Database** > Buat Database > Pilih **Test Mode** (aturan baca-tulis diset ke `true`).

### 5. Menjalankan Project
Pastikan emulator sudah menyala atau perangkat fisik sudah terhubung.
```bash
flutter run
```

---

## ðŸ“¦ Build Instructions

Untuk merilis aplikasi ke tahap produksi, gunakan perintah berikut:

### APK Generation (Android)
Menghasilkan file `.apk` biasa untuk dibagikan secara manual:
```bash
flutter build apk --release
```
*Output berada di: `build/app/outputs/flutter-apk/app-release.apk`*

### App Bundle (Play Store)
Menghasilkan format `.aab` untuk diunggah ke Google Play Store:
```bash
flutter build appbundle --release
```

### Debug Build
Jika butuh build khusus debug untuk *profiling*:
```bash
flutter build apk --debug
```

---

## ðŸŒ Environment Setup

Proyek ini tidak menggunakan file `.env` klasik karena mengandalkan arsitektur Firebase yang tersentralisasi dalam `firebase_options.dart`.

*   **Firebase Config:** Segala bentuk rahasia (API Key, App ID, Sender ID) tertanam dengan aman di dalam `lib/firebase_options.dart`. File ini di-_generate_ secara unik per sistem dan tidak direkomendasikan untuk dibagikan ke publik jika database bersifat _production_.
*   **Secret Handling:** Pada tahap _development_, _Realtime Database Rules_ diset ke `true`. Namun untuk rilis resmi, Anda wajib menambahkan aturan proteksi tambahan (Autentikasi).

---

## ðŸ”— Dependency Overview

| Package | Kegunaan Utama |
| :--- | :--- |
| **`flutter_local_notifications`** | Jantung dari aplikasi ini; menangani pemunculan popup dan bunyi alarm persis di jam yang dijadwalkan, bahkan saat aplikasi ditutup. |
| **`timezone` & `flutter_timezone`** | Penting untuk memastikan sinkronisasi zona waktu (misalnya WIB, WITA, WIT) agar notifikasi alarm lokal tidak melenceng akibat perbedaan UTC. |
| **`firebase_database`** | Mengirimkan JSON jadwal (Waktu, Nama Obat) ke Cloud agar dapat ditangkap secara otomatis oleh modul Wi-Fi (ESP32 V3) di kotak obat. |
| **`shared_preferences`** | Menghindari _loading_ kosong saat aplikasi baru dibuka dengan cara men-cache jadwal terakhir di penyimpanan internal HP. |
| **`google_fonts`** | Memberikan kustomisasi font untuk seluruh aplikasi demi estetika modern tanpa harus mendownload font statis `.ttf` secara manual. |

---
*Dokumentasi ini dibuat secara otomatis dengan bantuan analisis berbasis Source Code langsung.*

