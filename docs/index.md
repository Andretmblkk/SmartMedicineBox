# ðŸ¥ Smart Medicine Tracker - Documentation Hub

Selamat datang di pusat dokumentasi teknis **Smart Medicine Tracker**. Halaman indeks ini dirancang khusus untuk memudahkan navigasi antar dokumen

---

## ðŸ§­ Quick Navigation (Navigasi Cepat)

Silakan klik tautan di bawah ini untuk melompat ke dokumentasi yang spesifik:

### ðŸ“ Arsitektur & Struktur
*   [[architecture.md]] â€” Penjelasan struktur UI-Driven, Layer Komponen, dan App Lifecycle.
*   [[ui_structure.md]] â€” Dekonstruksi visual `BerandaScreen`, Widgets, dan sistem Tema.
*   [[dfd.md]] â€” Visualisasi Data Flow Diagram (DFD Level 0 & Level 1) untuk alur sistem.

### ðŸ”Œ Integrasi Data & Backend
*   [[api_backend.md]] â€” Arsitektur *Serverless Backend* tanpa API konvensional.
*   [[firebase.md]] â€” Integrasi Realtime Database sebagai *Message Broker* untuk modul IoT (ESP32 V3).
*   [[database_structure.md]] â€” Skema JSON pada `SharedPreferences` (Lokal) dan Firebase (Cloud).
*   [[state_management.md]] â€” Penjelasan persistensi data lokal dan siklus `setState`.

### ðŸ§  Logika & Alur Aplikasi
*   [[business_logic.md]] â€” Algoritma unik pembuatan ID Notifikasi, *Timezone shift*, dan penghapusan data.
*   [[routing.md]] â€” Pola navigasi (Imperative Routing) dan cara pengembalian data antar layar.

### ðŸ› ï¸ Setup & Pemecahan Masalah
*   [[setup_guide.md]] â€” Langkah-langkah kloning proyek, setup FlutterFire, hingga konfigurasi *Android Permissions*.
*   [[dependency_map.md]] â€” Peta grafik untuk dependensi pustaka (*packages*) dan interaksi kelas.
*   [[troubleshooting.md]] â€” Solusi untuk *crash* saat instalasi Firebase atau notifikasi gagal muncul.

---

## ðŸ“¦ Daftar Modul Aplikasi (Module Registry)

Berikut adalah daftar modul komponen utama yang menyusun kode sumber proyek ini:

### ðŸ“± Screens (`lib/screens/`)
*   `beranda_screen.dart` : *Dashboard* utama dan pusat *state management* jadwal.
*   `tambah_jadwal_screen.dart` : Form *Data Entry* untuk membuat alarm obat baru.

### ðŸ§© Widgets (`lib/widgets/`)
*   `medicine_schedule_card.dart` : Kartu penampil entitas tunggal obat.
*   `quick_stat_card.dart` : Kartu indikator metrik cepat.
*   `adherence_ring.dart` : Lingkaran indikator kepatuhan *(Progress Bar)*.

### âš™ï¸ Services (`lib/services/`)
*   `notification_service.dart` : Modul *wrapper* OS untuk Android/iOS Local Notification.
*   `firebase_schedule_service.dart` : Modul pengunggah *payload* JSON ke Firebase.

---

## ðŸ”— Referensi Root

Untuk dokumentasi di luar folder `docs/`:
*   [[../README.md|README Utama Proyek]] â€” *Overview*, fitur, dan stack teknologi.
*   [[../PROJECT_DOCUMENTATION.md|Project Documentation]] â€” Dokumen ringkasan *onboarding* utama dan *technical debt*.

> **Tips untuk pengguna Obsidian:** Pastikan pengaturan *Wikilink* (`[[ ]]`) pada vault Anda dalam keadaan aktif agar tautan di atas otomatis saling terhubung dan memunculkan diagram grafik (Graph View) yang indah.

