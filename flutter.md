# Panduan Menghubungkan Flutter ke Firebase (Realtime Database IoT)

Dokumen ini menjelaskan langkah demi langkah cara menghubungkan aplikasi Flutter "Smart Medicine Tracker" dengan layanan Firebase. Langkah ini sangat penting agar jadwal obat yang diinput oleh pengguna di aplikasi bisa terkirim ke internet (Firebase), lalu dibaca oleh sensor (seperti ESP32 V3) untuk menggerakkan servo pada kotak obat.

## 1. Membuat Project di Firebase Console
**Tujuan:** Menyiapkan wadah atau server *cloud* di database Google untuk menampung data aplikasi Anda.
* **Langkah:** Buka [Firebase Console](https://console.firebase.google.com/), buat project baru (misal: `smart-medicine-box`). 
* **Fungsi:** Firebase akan bertindak sebagai "jembatan" atau "kurir" antara aplikasi Flutter (yang mengirim data) dan Sensor IoT (yang menerima data).

## 2. Mengaktifkan Realtime Database & Mengubah "Rules" (Aturan)
**Tujuan:** Membuat ruang khusus untuk menyimpan data jadwal obat dalam format yang cepat, ringan, dan mudah dibaca oleh sensor hardware.
* **Langkah:** Buka menu Realtime Database, klik "Create Database", lalu pilih "Start in test mode". Kemudian di tab "Rules", ubah nilai `.read` dan `.write` menjadi `true`.
* **Fungsi:** 
    * **Test Mode & Rules = true:** Mengizinkan aplikasi dan sensor untuk membaca serta menulis data tanpa perlu fitur login (Authentication). Ini sangat memudahkan untuk pembuatan prototype IoT karena sensor bisa langsung mengakses data tanpa token akses yang rumit.

## 3. Instalasi Firebase CLI (`firebase-tools`)
**Tujuan:** Memasang program pembantu dari Google di komputer Anda agar terminal VS Code bisa berkomunikasi langsung dengan server Firebase.
* **Perintah:** `npm install -g firebase-tools`
* **Fungsi:** `npm` (Node Package Manager) akan mendownload program Firebase Command Line Interface (CLI) ke seluruh sistem komputer (`-g` atau global). Dengan terpasangnya program ini, komputer Anda menjadi paham ketika Anda mengetikkan perintah seperti `firebase login`.

## 4. Login Akun Firebase di Terminal
**Tujuan:** Memverifikasi bahwa terminal VS Code diizinkan untuk mengakses project Firebase yang telah Anda buat sebelumnya.
* **Perintah:** `firebase login`
* **Fungsi:** Mengamankan akun Anda. Terminal akan meminta izin melalui browser (Google Login) agar sistem Anda terotorisasi untuk melihat daftar project Firebase (seperti `smart-medicine-box`).

## 5. Instalasi FlutterFire CLI
**Tujuan:** Menginstal alat tambahan khusus yang dibuat agar framework Flutter bisa berkomunikasi dengan Firebase secara otomatis.
* **Perintah:** `dart pub global activate flutterfire_cli`
* **Fungsi:** Di masa lalu, menghubungkan aplikasi Flutter ke Firebase sangat manual (harus mendownload dan memindah file rahasia seperti `google-services.json` satu per satu). Alat `flutterfire_cli` ini diciptakan agar proses tersebut berjalan secara otomatis hanya dengan satu kali klik.

## 6. Mengkonfigurasi (Configure) Project Flutter
**Tujuan:** Menarik pengaturan (ID Project, API Key) dari server Firebase dan menanamkannya ke dalam kode Flutter Anda.
* **Perintah:** `dart pub global run flutterfire_cli:flutterfire configure` 
* **Fungsi:** 
    * Perintah ini mendaftarkan aplikasi Flutter Anda (nama paketnya: `com.example.medicinetreatment`) secara resmi ke project Firebase Anda di Cloud.
    * Menghasilkan file bernama **`firebase_options.dart`** secara otomatis. File ini sangat krusial karena ia menyimpan semua "kunci rahasia" (API Keys) yang dibutuhkan aplikasi Flutter untuk mengakses Firebase. Tanpa file ini, aplikasi tidak akan tahu harus mengirim data jadwal ke server milik siapa.

## 7. Inisialisasi Firebase di `main.dart`
**Tujuan:** Membangunkan (menyalakan) koneksi Firebase saat aplikasi Flutter pertama kali dibuka di HP.
* **Kode yang ditambahkan:** 
  ```dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  ```
* **Fungsi:** Menyuruh aplikasi untuk membaca kunci rahasia yang ada di dalam `firebase_options.dart` tadi, lalu membuat koneksi internet aktif ke Realtime Database Anda. Setelah koneksi ini terjalin, setiap kali pengguna menekan tombol Simpan di aplikasi, data otomatis langsung ter-push (terkirim) ke Firebase.

---
Dengan ketujuh langkah ini, jembatan data antara aplikasi Flutter Anda dan Firebase sudah terbangun dengan kokoh. Selanjutnya Anda hanya perlu berfokus memprogram Sensor (ESP32 V3) pada Arduino IDE untuk membaca data dari jembatan tersebut dan menggerakkan servo di jam yang tepat.

