# Backend & API Struktur

Dokumen ini memaparkan penjelasan arsitektur komunikasi data *(backend routing)* dari aplikasi Smart Medicine Tracker.

---

## 1. Konsep *Serverless Backend*

Smart Medicine Tracker adalah aplikasi yang sepenuhnya menerapkan konsep **Serverless Backend**. 

Itu berarti aplikasi **TIDAK** menggunakan:
1. RESTful API tradisional (seperti Laravel, ExpressJS, atau Django).
2. Protokol HTTP konvensional menggunakan package seperti `http` atau `dio`.
3. Server terpisah yang perlu dikelola secara manual (VPS/Shared Hosting).

Sebagai gantinya, seluruh fungsi infrastruktur *Backend*, termasuk pangkalan data (*Database*), dikendalikan dan dihosting oleh infrastruktur dari **Google Firebase**.

---

## 2. Mekanisme Komunikasi (Firebase Realtime Database)

Lalu lintas pertukaran data ditangani murni via protokol WebSockets *Realtime Database Firebase*. Protokol ini sangat ringan dan difokuskan pada sinkronisasi status waktu-nyata (Real-time state synchronization), alih-alih pola *Request-Response* biasa.

### A. Interkoneksi IoT (The Bridge)
Arsitektur Firebase digunakan karena proyek ini membutuhkan perangkat keras tertanam (Embedded Hardware IoT seperti modul Wi-Fi ESP8266 atau ESP32). ESP8266 hanya dapat menahan jumlah memori *(heap)* dan koneksi yang sangat minim. Firebase memungkinkan ESP8266 melakukan *Stream / Long-polling / GET request* JSON yang sangat kecil tanpa overhead (beban) koneksi server tradisional.

*   Aplikasi -> Firebase -> IoT (Kotak Obat Fisik).
*   *File Utama yang menangani:* `lib/services/firebase_schedule_service.dart`.

---

## 3. Mengapa Tidak Ada REST API Lokal?

Anda mungkin tidak menemukan folder `models/api` atau `services/api_client.dart` dalam kode sumber karena:
*   Penyimpanan utama berbasis *Local-First* (`SharedPreferences`). Aplikasi membaca, menulis, dan beroperasi di atas data lokal tanpa menunggu sinyal konfirmasi dari internet.
*   Internet hanya digunakan sebagai tugas sampingan *(Background Task)* untuk menyalin data *(Backup/Mirroring)* ke database cloud. 
*   Pendekatan ini sengaja dirancang agar fungsi utama aplikasi, yaitu **Alarm Notifikasi Pengingat Obat**, tetap bisa bekerja 100% sempurna meskipun pengguna sedang berada di area tanpa koneksi internet (Offline).

---

## 4. Keamanan Integrasi (Security Concerns)

Karena aplikasi mengimplementasikan konsep "Tempatkan ke Database" (Push to DB) tanpa validasi API di tengahnya (ketiadaan backend yang berfungsi menyaring permintaan HTTP POST), keamanan di-shift *(digeser)* ke layer konfigurasi Firebase Security Rules. 

Pada saat ini (fase prototipe), konfigurasi dibiarkan terbuka (`.read: true`, `.write: true`) sehingga tidak ada token Bearer, API Keys rahasia (yang di-generate server), maupun protokol *OAuth* yang ada di dalam source code aplikasi. Otentikasi sepenuhnya dilewati. Jika hendak menaikkan tingkat keamanan API ini untuk *Production*, Anda wajib mengaktifkan modul Autentikasi Firebase di dalam aplikasi Flutter dan membatasi `write` hanya untuk pengguna yang memiliki Token Firebase yang valid.
